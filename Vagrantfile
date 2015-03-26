# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version.
VAGRANTFILE_API_VERSION = "2"

# Cardinal parameters of virtual machine.
HOST_NAME = '__HOST_NAME__'
CPU_NUMBER = 2
RAM = 2048
VRAM = 32
BOX = '__BOX__'
BOOTSTRAP_FILE = 'bootstrap.rb'

TCP_FORWARD_PORTS = [
  {:host => __HOST_PORT__, :guest => __GUEST_PORT__}
]
SYNCED_FOLDERS = [
  {:host_path => '__HOST_FOLDER_PATH__', :guest_path => '__GUEST_FOLDER_PATH__'}
]

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config| 
  config.vm.box = BOX
  config.vm.box_check_update = true
  
  if File.file? BOOTSTRAP_FILE
    config.vm.provision :shell, path: BOOTSTRAP_FILE
  end
  
  config.vm.hostname = HOST_NAME
  
  TCP_FORWARD_PORTS.each do |tfp|
    config.vm.network :forwarded_port, host: tfp[:host], guest: tfp[:guest], protocol: 'tcp'
  end

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # If true, then any SSH connections made will enable agent forwarding.
  # Default value: false
  # config.ssh.forward_agent = true

  SYNCED_FOLDERS.each do |fp|
    config.vm.synced_folder fp[:host_path], fp[:guest_path], create: true
  end

  config.vm.provider "virtualbox" do |vb|
    # Boot with headless mode.
    vb.gui = false
    vb.name = HOST_NAME
    vb.customize ["modifyvm", :id, "--cpus", "#{CPU_NUMBER}"]
    vb.customize ["modifyvm", :id, "--memory", "#{RAM}"]
    vb.customize ["modifyvm", :id, "--vram", "#{VRAM}"]
    vb.customize ["modifyvm", :id, "--chipset", "ich9"]
  end
end
