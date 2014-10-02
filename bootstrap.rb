#!/usr/bin/env ruby

require 'rubygems'
require 'json'
require 'open3'
require 'fileutils'

module Setup
  module Ubuntu
    REPOSITORIES = [
      'ppa:mercurial-ppa/releases',
      'ppa:git-core/ppa'
    ]
    PACKAGES = [
      'mercurial',
      'git',
      'bzr',
      'pkg-config',
      'htop'
    ]
  end
  
  module Golang
    GO_ENV_VARS_FILE = '/etc/profile.d/goevars.sh'
    GO_ROOT = '/usr/local/go'
    GO_PATH = '/usr/local/gopath'
    STABLE_REVISION = '1ebe0bc97711'
    PACKAGES = [
      'github.com/cihub/seelog'
    ]
  end
  
  module Rubylang
    GEMS = []
  end
  
  module Pythonlang
    PACKAGES = []
  end
  
  module Nodejs
    PACKAGES = []
  end
end

# Script guts.

STDOUT.sync = true

class Logger
  def self.info(mes)
    puts "[INFO] #{mes}"
  end

  def self.error(mes)
    puts "[ERROR] #{mes}"
  end

  def self.progress_info(mes)
    puts "\n---> #{mes}..."
  end
end

class Command
  attr_accessor :working_directory

  def initialize(command, working_directory = Dir.getwd)
    @command = command
    @working_directory = working_directory
  end

  def execute_ordinarily(*args)
    if args.length == 0
      _execute(@command)
      return
    end
    _execute(@command % args)
  end

  def execute_separately(args)
    args.each {|arg|
      _execute(@command % "#{arg}")
    }
  end

  def execute_jointly(args, sep = ' ')
    _execute(@command % "#{args.join(sep)}")
  end

  private
    def _execute(c)
      Dir.chdir(@working_directory) do
        Open3.popen2e(c) do |i, oe, t|
          oe.each {|line|
            puts line
          }
        end
      end
    end
end

def command_known?(name)
  `which #{name}`
  $?.success?
end

def gem_installed?(name)
  (`gem list #{name} -i`.strip!).eql? 'true'
end

def no_rebuild_needed?(dir, rev)
  # (`cd #{dir}; hg log -r. --template "{node|short}"`).eql? rev
  `cd #{dir}; hg pull`
  (`cd #{dir}; hg update #{rev}`.strip!).eql? '0 files updated, 0 files merged, 0 files removed, 0 files unresolved'
end

def repository_added?(repo)
  # File.readlines('/etc/apt/sources.list').each do |line|
  #   if line.include? repo
  #     return true
  #   end
  # end
  Dir['/etc/apt/sources.list.d/*.list'].each do |fn|
    if fn.split('/').last.start_with? repo[4..repo.length-1].split('/')[0]
      return true
    end
  end
  return false
end

def head_section(name, show = true)
  if show
    Logger.progress_info(name)
  end
  if block_given?
    yield
  end
end

if __FILE__ == $0
  head_section('Adding PPA repositories, if any', Setup::Ubuntu::REPOSITORIES.any?) do
    Setup::Ubuntu::REPOSITORIES.each do |repo|
      Command.new("add-apt-repository -y #{repo}").execute_ordinarily() unless repository_added?(repo)
    end
  end

  head_section('Updating Ubuntu packages') do
    Command.new('apt-get update').execute_ordinarily()
  end

  head_section('Installing required Ubuntu packages, if any', Setup::Ubuntu::PACKAGES.any?) do
    Command.new("apt-get install -y %s").execute_jointly(Setup::Ubuntu::PACKAGES)
  end

  head_section('Checking Go distributive integrity')
  if !File.file?(Setup::Golang::GO_ENV_VARS_FILE)
    Logger.info('Go environment file not found')
    goroot_path = Setup::Golang::GO_ROOT
    gopath_path = Setup::Golang::GO_PATH
    # Temporarily set GOROOT and GOPATH environment variables (until we restart the bash session).
    ENV['GOROOT'] = goroot_path
    ENV['GOPATH'] = gopath_path
    ENV['PATH'] = "#{ENV['PATH']}:#{goroot_path}/bin:#{gopath_path}/bin"
    
    head_section('Installing Go distributive')
    case
    when Dir.exists?(goroot_path)
      Logger.info('Remove GOROOT contents')
      FileUtils.rm_rf(Dir.glob("#{goroot_path}/*"))
    when !Dir.exists?(goroot_path)
      Logger.info('Create GOROOT directory')
      FileUtils.mkdir_p(goroot_path)
    when Dir.exists?(gopath_path)
      Logger.info('Remove GOPATH contents')
      FileUtils.rm_rf(Dir.glob("#{gopath_path}/*"))
    when !Dir.exists?(gopath_path)
      Logger.info('Create GOPATH directory')
      FileUtils.mkdir_p(gopath_path)
    end

    Logger.info('Clone official Go repository')
    Command.new("hg clone -u #{Setup::Golang::STABLE_REVISION} https://code.google.com/p/go #{goroot_path}").execute_ordinarily()
    Command.new('./all.bash', "#{goroot_path}/src").execute_ordinarily()

    Logger.info('Create Go environment file')
    File.open(Setup::Golang::GO_ENV_VARS_FILE, 'w') do |f|
      f.write("export GOROOT=#{goroot_path}\n")
      f.write("export GOPATH=#{gopath_path}\n")
      f.write("export PATH=\$PATH:\$GOROOT/bin:\$GOPATH/bin\n")
    end
  else
    case
    when !ENV.has_key?('GOROOT')
      Logger.error('Go environment file found but GOROOT not set: abort running script')
      abort
    when !ENV.has_key?('GOPATH')
      Logger.error('Go environment file found but GOPATH not set: abort running script')
      abort
    when !command_known?('go')
      Logger.error('Go environment file found but go command not found: abort running script')
      abort
    end
    Logger.info('Go environment file found')
    # Update Go distributive upto the given stable version if needed.
    head_section('Searching for Go distributive updates') do
      unless no_rebuild_needed?(Setup::Golang::GO_ROOT, Setup::Golang::STABLE_REVISION)
        Logger.info('Rebuild Go distributive')
        Command.new('./all.bash', File.join(Setup::Golang::GO_ROOT, 'src')).execute_ordinarily()
      else
        Logger.info('Go distributive seemed up-to-date')
      end
    end
  end

  head_section('Installing Go packages, if any', Setup::Golang::PACKAGES.any?) do
    Command.new("go get -v %s").execute_separately(Setup::Golang::PACKAGES)
  end

  head_section('Installing Node.js packages, if any', Setup::Nodejs::PACKAGES.any?) do
    Command.new("npm install -g %s").execute_separately(Setup::Nodejs::PACKAGES)
  end

  head_section('Installing Ruby gems, if any', Setup::Rubylang::GEMS.any?) do
    Setup::Rubylang::GEMS.each do |g|
      unless gem_installed?(g)
        Command.new("gem install #{g}").execute_ordinarily()
      end
    end
  end
end