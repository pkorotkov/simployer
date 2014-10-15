#!/usr/bin/env ruby

require 'rubygems'
require 'open3'
require 'fileutils'

module Ubuntu
  REPOSITORIES = [
    'ppa:git-core/ppa',
    'ppa:mercurial-ppa/releases'
  ]

  PACKAGES = [
    'git',
    'mercurial',
    'bzr',
    'pkg-config',
    'htop'
  ]

  def Ubuntu.repository_added?(repo)
    rs = repo[4..repo.length-1].split('/')[0]
    File.readlines('/etc/apt/sources.list').each do |line|
      if line.include?(rs)
        return true
      end
    end
    Dir['/etc/apt/sources.list.d/*.list'].each do |fn|
      if fn.split('/').last.start_with?(rs)
        return true
      end
    end
    return false
  end

  def Ubuntu.apply
    head_section("Applying #{self.name} setup", true, true) do
      head_section('Adding PPA repositories, if any', REPOSITORIES.any?) do
        REPOSITORIES.each do |repo|
          Command.new("add-apt-repository -y #{repo}").execute_ordinarily() unless repository_added?(repo)
        end
      end
      head_section('Updating Ubuntu packages') do
        Command.new('apt-get update').execute_ordinarily()
      end
      head_section('Installing required Ubuntu packages, if any', PACKAGES.any?) do
        Command.new("apt-get install -y %s").execute_jointly(PACKAGES)
      end
    end
  end
end

module Golang
  GO_ENV_VARS_FILE = '/etc/profile.d/goevars.sh'
  GO_ROOT = '/usr/local/go'
  GO_PATH = '/usr/local/gopath'
  STABLE_REVISION = 'f8a253b426f1'

  PACKAGES = [
    'github.com/cihub/seelog'
  ]
  
  def Golang.no_rebuild_needed?(dir, rev)
    before_rev = `cd #{dir}; hg log -r. --template "{node|short}"`
    `cd #{dir}; hg pull`
    return (`cd #{dir}; hg update #{rev}`.strip!).eql?('0 files updated, 0 files merged, 0 files removed, 0 files unresolved'), before_rev
  end

  def Golang.apply
    head_section("Applying #{self.name} setup", true, true) do
      head_section('Checking Go distributive integrity')
      if !File.file?(GO_ENV_VARS_FILE)
        Logger.info('Go environment file not found')
        # Temporarily set GOROOT and GOPATH environment variables (until we restart the bash session).
        ENV['GOROOT'] = GO_ROOT
        ENV['GOPATH'] = GO_PATH
        ENV['PATH'] = "#{ENV['PATH']}:#{GO_ROOT}/bin:#{GO_PATH}/bin"
        
        head_section('Installing Go distributive')
        case
        when Dir.exists?(GO_ROOT)
          Logger.info('Remove GOROOT contents')
          FileUtils.rm_rf(Dir.glob("#{GO_ROOT}/*"))
        when !Dir.exists?(GO_ROOT)
          Logger.info('Create GOROOT directory')
          FileUtils.mkdir_p(GO_ROOT)
        when Dir.exists?(GO_PATH)
          Logger.info('Remove GOPATH contents')
          FileUtils.rm_rf(Dir.glob("#{GO_PATH}/*"))
        when !Dir.exists?(GO_PATH)
          Logger.info('Create GOPATH directory')
          FileUtils.mkdir_p(GO_PATH)
        end

        Logger.info('Clone official Go repository')
        Command.new("hg clone -u #{STABLE_REVISION} https://code.google.com/p/go #{GO_ROOT}").execute_ordinarily()
        Command.new('./all.bash', "#{GO_ROOT}/src").execute_ordinarily()

        Logger.info('Create Go environment file')
        File.open(GO_ENV_VARS_FILE, 'w') do |f|
          f.write("export GOROOT=#{GO_ROOT}\n")
          f.write("export GOPATH=#{GO_PATH}\n")
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
          nrn, br = no_rebuild_needed?(GO_ROOT, STABLE_REVISION)
          unless nrn
            Logger.info("Update Go distributive version (#{br} -> #{STABLE_REVISION})")
            Command.new('./all.bash', File.join(GO_ROOT, 'src')).execute_ordinarily()
          else
            Logger.info('Go distributive needed no date')
          end
        end
      end
      head_section('Installing Go packages, if any', PACKAGES.any?) do
        Command.new("go get -v %s").execute_separately(PACKAGES)
      end
    end
  end
end

module Rubylang
  GEMS = []

  def Rubylang.gem_installed?(name)
    (`gem list #{name} -i`.strip!).eql?('true')
  end

  def Rubylang.apply
    head_section("Applying #{self.name} setup", true, true) do
      head_section('Installing Ruby gems, if any', GEMS.any?) do
        GEMS.each do |g|
          unless gem_installed?(g)
            Command.new("gem install #{g}").execute_ordinarily()
          end
        end
      end
    end
  end
end

module Nodejs
  PACKAGES = []

  def Nodejs.apply
    head_section("Applying #{self.name} setup", true, true) do
      head_section('Installing Node.js packages, if any', PACKAGES.any?) do
        Command.new("npm install -g %s").execute_separately(PACKAGES)
      end
    end
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
    args.each do |arg|
      _execute(@command % "#{arg}")
    end
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

def head_section(name, apply = true, upper_case = false)
  if apply
    Logger.progress_info(upper_case ? name.upcase : name)
    if block_given?
      yield
    end
  end
end

if __FILE__ == $0
  Ubuntu.apply
  Golang.apply
  Nodejs.apply
  Rubylang.apply
end