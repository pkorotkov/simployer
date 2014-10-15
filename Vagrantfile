# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version.
VAGRANTFILE_API_VERSION = "2"
# Name of virtual machine.
HOST_NAME = "__HOST_NAME__"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config| 
  config.vm.box = "__BOX__"
  config.vm.provision :shell, path: "bootstrap.rb"
  config.vm.hostname = HOST_NAME
  config.vm.network :forwarded_port, host: __HOST_PORT__, guest: __GUEST_PORT__, protocol: 'tcp'

  config.vm.box_check_update = true

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

  config.vm.synced_folder "gopath/", "/usr/local/gopath", create: true

  config.vm.provider "virtualbox" do |vb|
    # Boot with headless mode.
    vb.gui = false
    vb.name = HOST_NAME
    vb.customize ["modifyvm", :id, "--memory", "2048"]
    vb.customize ["modifyvm", :id, "--chipset", "ich9"]
  end
end
