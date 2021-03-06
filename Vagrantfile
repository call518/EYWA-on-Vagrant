# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  #config.vm.boot_timeout = 600
  #config.vm.provider :virtualbox do |vb|
  #  vb.gui = true
  #end
  #config.ssh.forward_agent = true
  config.ssh.forward_x11 = true

  master_ip = "192.168.33.10"
  master_ip_pri = "172.20.33.10"
  ptr_head = "33.168.192"

  #opennebula_version = "4.6"
  opennebula_version = "4.10"

  oneadmin_pw = "passw0rd"
  vm_root_pw = "1234"

  sunstone_listen_addr = "0.0.0.0"
  sunstone_listen_port = "9869"

  #pub_gw_mac = "080000000001"

  config.vm.box = "trusty64"
  config.vm.box_url = "https://onedrive.live.com/download?resid=28f8f701dc29e4b9%21247"

  ### bridge parameters.
  ## resources/puppet/templates/VSe-master.cfg.erb
  ## resources/puppet/templates/VSe-slave.cfg.erb
  #---------------------
  #bridge_waitport 0
  #bridge_maxwait 0
  #bridge_ageing 0
  #bridge_maxage 0
  #bridge_fd 0
  #bridge_hello 2
  #---------------------


  config.vm.define "master" do |master|
    my_ip = "#{master_ip}"
    my_ip_pri = "#{master_ip_pri}"
    master.vm.hostname = "master"
    vnc_port = "55910"
    #master.vm.network "private_network", ip: "#{master_ip}", auto_config: false, virtualbox__intnet: true
    master.vm.network "private_network", ip: "#{master_ip}", auto_config: false
    master.vm.network "private_network", ip: "#{master_ip_pri}", virtualbox__intnet: true
    master.vm.network "forwarded_port", guest: "#{sunstone_listen_port}", host: "#{sunstone_listen_port}"
    master.vm.network "forwarded_port", guest: "#{vnc_port}", host: "#{vnc_port}", protocol: 'tcp'
    master.vm.network "forwarded_port", guest: 53, host: 53, protocol: 'tcp'
    master.vm.network "forwarded_port", guest: 53, host: 53, protocol: 'udp'
    master.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--cpus", "2"]
      vb.customize ["modifyvm", :id, "--memory", "2048"]
      #vb.customize ["modifyvm", :id, "--chipset", "ich9"]
      #vb.customize ["modifyvm", :id, "--pae", "on"]
      #vb.customize ["modifyvm", :id, "--ioapic", "on"]
      #vb.customize ["modifyvm", :id, "--hpet", "on"]
      #vb.customize ["modifyvm", :id, "--hwvirtex", "on"]
      #vb.customize ["modifyvm", :id, "--nestedpaging", "on"]
      #vb.customize ["modifyvm", :id, "--largepages", "on"]
      vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
      vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
      #vb.customize ["modifyvm", :id, "--macaddress2", "#{pub_gw_mac}"]
      #vb.customize ["modifyvm", :id, "--natdnsproxy2", "on"]
    end
    master.vm.provision "shell", path: "resources/puppet/scripts/upgrade-puppet.sh"
    master.vm.provision "shell", path: "resources/puppet/scripts/bootstrap.sh"
    master.vm.provision "shell", inline: <<-SCRIPT
      if test ! -f /root/.created-routing; then
        #ip link set mtu 1600 eth1
        #ip link set mtu 1600 eth2
        #iptables -t nat -I POSTROUTING -o eth0 -s 192.168.33.0/24 -j MASQUERADE
        route add -net 239.0.0.0/8 dev eth2
        touch /root/.created-routing
      fi
    SCRIPT
    master.vm.provision "puppet" do |puppet|
      puppet.working_directory = "/vagrant/resources/puppet"
      puppet.hiera_config_path = "resources/puppet/hiera.yaml"
      puppet.manifests_path = "resources/puppet/manifests"
      puppet.manifest_file  = "base.pp"
      puppet.options = "--verbose"
    end
    master.vm.provision "puppet" do |puppet|
      puppet.working_directory = "/vagrant/resources/puppet"
      puppet.hiera_config_path = "resources/puppet/hiera.yaml"
      puppet.manifests_path = "resources/puppet/manifests"
      puppet.manifest_file  = "common.pp"
      puppet.facter = {
        "opennebula_version" => "#{opennebula_version}",
      }
      puppet.options = "--verbose"
    end
    master.vm.provision "puppet" do |puppet|
      puppet.working_directory = "/vagrant/resources/puppet"
      puppet.hiera_config_path = "resources/puppet/hiera.yaml"
      puppet.manifests_path = "resources/puppet/manifests"
      puppet.manifest_file  = "master.pp"
      puppet.facter = {
        "master_ip" => "#{master_ip}",
        "oneadmin_pw" => "#{oneadmin_pw}",
        "vm_root_pw" => "#{vm_root_pw}",
        "sunstone_listen_addr" => "#{sunstone_listen_addr}",
        "sunstone_listen_port" => "#{sunstone_listen_port}",
      }
      puppet.options = "--verbose"
    end
    master.vm.provision "puppet" do |puppet|
      puppet.working_directory = "/vagrant/resources/puppet"
      puppet.hiera_config_path = "resources/puppet/hiera.yaml"
      puppet.manifests_path = "resources/puppet/manifests"
      puppet.manifest_file  = "slave.pp"
      puppet.facter = {
        "master_ip" => "#{master_ip}",
        "my_ip" => "#{my_ip}",
        "my_ip_pri" => "#{my_ip_pri}",
        #"pub_gw_mac" => "#{pub_gw_mac}",
      }
      puppet.options = "--verbose"
    end
    master.vm.provision "puppet" do |puppet|
      puppet.working_directory = "/vagrant/resources/puppet"
      puppet.hiera_config_path = "resources/puppet/hiera.yaml"
      puppet.manifests_path = "resources/puppet/manifests"
      puppet.manifest_file  = "vnc.pp"
      puppet.facter = {
        "oneadmin_pw" => "#{oneadmin_pw}",
        "vnc_port" => "#{vnc_port}"
      }
      puppet.options = "--verbose"
    end
    master.vm.provision "puppet" do |puppet|
      puppet.working_directory = "/vagrant/resources/puppet"
      puppet.hiera_config_path = "resources/puppet/hiera.yaml"
      puppet.manifests_path = "resources/puppet/manifests"
      puppet.manifest_file  = "eywa.pp"
      puppet.facter = {
        "master_ip" => "#{master_ip}",
        "my_ip" => "#{my_ip}",
        "my_ip_pri" => "#{my_ip_pri}",
        "opennebula_version" => "#{opennebula_version}",
        "oneadmin_pw" => "#{oneadmin_pw}",
        "ptr_head" => "#{ptr_head}",
      }
      puppet.options = "--verbose"
    end
  end

  num_slave_nodes = 2 ## (WARNING) Max:2, and sync with hiera file -> "resources/puppet/hieradata/hosts.json"
  slave_ip_base = "192.168.33."
  slave_ips = num_slave_nodes.times.collect { |n| slave_ip_base + "#{n+11}" }
  slave_ip_pri_base = "172.20.33."
  slave_ips_pri = num_slave_nodes.times.collect { |n| slave_ip_pri_base + "#{n+11}" }
  
  num_slave_nodes.times do |n|
    config.vm.define "slave-#{n+1}" do |slave|
      slave_ip = slave_ips[n]
      slave_ip_pri = slave_ips_pri[n]
      my_ip = "#{slave_ip}"
      my_ip_pri = "#{slave_ip_pri}"
      slave.vm.hostname = "slave-#{n+1}"
      vnc_port = "559#{n+11}"
      #slave.vm.network "private_network", ip: "#{slave_ip}", virtualbox__intnet: true
      slave.vm.network "private_network", ip: "#{slave_ip}", auto_config: false
      slave.vm.network "private_network", ip: "#{slave_ip_pri}", virtualbox__intnet: true
      slave.vm.network "forwarded_port", guest: "#{vnc_port}", host: "#{vnc_port}", protocol: 'tcp'
      slave.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--cpus", "2"]
        vb.customize ["modifyvm", :id, "--memory", "2048"]
        #vb.customize ["modifyvm", :id, "--chipset", "ich9"]
        #vb.customize ["modifyvm", :id, "--pae", "on"]
        #vb.customize ["modifyvm", :id, "--ioapic", "on"]
        #vb.customize ["modifyvm", :id, "--hpet", "on"]
        #vb.customize ["modifyvm", :id, "--hwvirtex", "on"]
        #vb.customize ["modifyvm", :id, "--nestedpaging", "on"]
        #vb.customize ["modifyvm", :id, "--largepages", "on"]
        vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
        vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
        #vb.customize ["modifyvm", :id, "--natdnsproxy2", "on"]
      end
      slave.vm.provision "shell", path: "resources/puppet/scripts/upgrade-puppet.sh"
      slave.vm.provision "shell", path: "resources/puppet/scripts/bootstrap.sh"
      slave.vm.provision "shell", inline: <<-SCRIPT
        if test ! -f /root/.created-routing; then
          #ip link set mtu 1600 eth1
          #ip link set mtu 1600 eth2
          #iptables -t nat -I POSTROUTING -o eth0 -s 192.168.33.0/24 -j MASQUERADE
          route add -net 239.0.0.0/8 dev eth2
          touch /root/.created-routing
        fi
      SCRIPT
      slave.vm.provision "puppet" do |puppet|
        puppet.working_directory = "/vagrant/resources/puppet"
        puppet.hiera_config_path = "resources/puppet/hiera.yaml"
        puppet.manifests_path = "resources/puppet/manifests"
        puppet.manifest_file  = "base.pp"
        puppet.options = "--verbose"
      end
      slave.vm.provision "puppet" do |puppet|
        puppet.working_directory = "/vagrant/resources/puppet"
        puppet.hiera_config_path = "resources/puppet/hiera.yaml"
        puppet.manifests_path = "resources/puppet/manifests"
        puppet.manifest_file  = "common.pp"
        puppet.facter = {
          "opennebula_version" => "#{opennebula_version}",
        }
        puppet.options = "--verbose"
      end
      slave.vm.provision "puppet" do |puppet|
        puppet.working_directory = "/vagrant/resources/puppet"
        puppet.hiera_config_path = "resources/puppet/hiera.yaml"
        puppet.manifests_path = "resources/puppet/manifests"
        puppet.manifest_file  = "slave.pp"
        puppet.facter = {
          "master_ip" => "#{master_ip}",
          "my_ip" => "#{my_ip}",
          "my_ip_pri" => "#{my_ip_pri}",
          #"pub_gw_mac" => "#{pub_gw_mac}",
        }
        puppet.options = "--verbose"
      end
      slave.vm.provision "puppet" do |puppet|
        puppet.working_directory = "/vagrant/resources/puppet"
        puppet.hiera_config_path = "resources/puppet/hiera.yaml"
        puppet.manifests_path = "resources/puppet/manifests"
        puppet.manifest_file  = "vnc.pp"
        puppet.facter = {
          "oneadmin_pw" => "#{oneadmin_pw}",
          "vnc_port" => "#{vnc_port}"
        }
        puppet.options = "--verbose"
      end
      slave.vm.provision "puppet" do |puppet|
        puppet.working_directory = "/vagrant/resources/puppet"
        puppet.hiera_config_path = "resources/puppet/hiera.yaml"
        puppet.manifests_path = "resources/puppet/manifests"
        puppet.manifest_file  = "eywa.pp"
        puppet.facter = {
          "master_ip" => "#{master_ip}",
          "my_ip" => "#{my_ip}",
          "my_ip_pri" => "#{my_ip_pri}",
          "opennebula_version" => "#{opennebula_version}",
          "oneadmin_pw" => "#{oneadmin_pw}",
          "ptr_head" => "#{ptr_head}",
        }
        puppet.options = "--verbose"
      end
    end
  end
end
