# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"

  # Increase memory: 3 GB
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "3072"
  end

  config.vm.box_check_update = true

  # Forward ssh
  config.vm.network "forwarded_port", guest: 22, host: 44142

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network "private_network", ip: "172.28.6.2"

  # Expose the current folder read-only
  config.vm.synced_folder ".", "/vagrant", :mount_options => ["ro"]

  config.vm.provision "docker",
    images: ["mariadb", "ruby:2.6.1-alpine"]
  config.vm.provision "shell", inline: <<-SHELL
    # Needed for the private network
    sudo apt-get install ifupdown

    # Install docker-compose
    sudo curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    # Clone gambe.ro
    cd /home/vagrant
    git clone https://github.com/gambe-ro/lobsters
    mv -v lobsters gambero
  SHELL
end
