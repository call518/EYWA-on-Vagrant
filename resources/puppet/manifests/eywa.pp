####################################################

include 'apt'

### Export Env: Global %PATH for "Exec"
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin" ] }

$oneadmin_home = "/var/lib/one"

package { "mysql-client":
    ensure   => installed,
    #ensure   => "5.5.41-0ubuntu0.14.04.1",
}

exec { "Set SUDO - /etc/sudoers (1)":
    command => "echo 'oneadmin    ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers",
    user    => "root",
    timeout => "0",
    unless  => "grep -q '^oneadmin    ALL=(ALL) NOPASSWD: ALL' /etc/sudoers",
    require => Package["mysql-client"],
}

exec { "Set SUDO - /etc/sudoers (2)":
    command => "echo 'Defaults env_keep -= \"HOME\"' >> /etc/sudoers",
    user    => "root",
    timeout => "0",
    unless  => "grep -q '^Defaults env_keep -= \"HOME\"' /etc/sudoers",
    require => Exec["Set SUDO - /etc/sudoers (1)"],
}

if $hostname == "master" {
  exec { "=== Waiting.... Downloading eywa_schema.sql.gz... ===":
      command  => "echo '=== Waiting.... eywa_schema.sql.gz... ==='",
      user     => "root",
      timeout  => "0",
      logoutput => true,
      require  => Exec["Set SUDO - /etc/sudoers (2)"],
  }
  
  exec { "Put eywa_schema.sql.gz":
      command  => "wget 'https://onedrive.live.com/download?resid=28f8f701dc29e4b9%2110238' -O /home/vagrant/eywa_schema.sql.gz",
      creates  => "/home/vagrant/eywa_schema.sql.gz",
      user     => "root",
      timeout  => "0",
      #logoutput => true,
      require  => Exec["=== Waiting.... Downloading eywa_schema.sql.gz... ==="],
  }
  
  exec { "Create eywa DB":
      command  => "mysql -uroot -p${oneadmin_pw} -e 'CREATE DATABASE eywa'",
      user     => "root",
      timeout  => "0",
      logoutput => true,
      unless   => "mysql -uroot -p${oneadmin_pw} -e 'USE eywa'",
      #require  => File["Put eywa_schema.sql"],
      require  => Exec["Put eywa_schema.sql.gz"],
  }
  
  exec { "Set eywa User/Pass":
      provider => shell,
      command  => "mysql -uroot -p${oneadmin_pw} -e \"GRANT ALL PRIVILEGES ON eywa.* TO 'eywa'@'localhost' IDENTIFIED BY '1234'\" && mysql -uroot -p${oneadmin_pw} -e \"GRANT ALL PRIVILEGES ON eywa.* TO 'eywa'@'%' IDENTIFIED BY '1234'\"",
      user     => "root",
      timeout  => "0",
      logoutput => true,
      unless   => "RESULT=`mysql -uroot -ppassw0rd -e \"SELECT user FROM mysql.user WHERE user='eywa'\"`; if [ -z \"$RESULT\" ]; then exit 1; else exit 0; fi",
      require  => Exec["Create eywa DB"],
  }
  
  exec { "=== Waiting.... Creating EYWA DB Schema... ===":
      command  => "echo '=== Waiting.... Creating EYWA DB Schema... ==='",
      user     => "root",
      timeout  => "0",
      logoutput => true,
      require  => Exec["Set eywa User/Pass"],
  }
  
  exec { "Create eywa Schema & Env.":
      command  => "zcat /home/vagrant/eywa_schema.sql | mysql -uroot -p${oneadmin_pw} eywa",
      user     => "root",
      timeout  => "0",
      logoutput => true,
      unless   => "mysql -uroot -p${oneadmin_pw} -e 'SELECT * FROM eywa.vm_info'",
      require  => Exec["=== Waiting.... Creating EYWA DB Schema... ==="],
  }
  
  file { "Put ${oneadmin_home}/remotes/hooks/eywa DIR":
      path     => "${oneadmin_home}/remotes/hooks/eywa",
      owner    => "oneadmin",
      group    => "oneadmin",
      mode     => 0775,
      source   => "/vagrant/resources/puppet/files/eywa-remotes",
      ensure   => directory,
      replace  => true,
      recurse  => true,
      require  => Exec["Create eywa Schema & Env."],
  }
  
  exec { "Set Testing SSH Key for EYWA-VM":
      command  => "sed -i \"s|@@__SSH_PUB_KEY__@@|$(cat /var/lib/one/.ssh/id_rsa.pub)|g\" ${oneadmin_home}/remotes/hooks/eywa/eywa_private_vm.tmpl",
      user     => "root",
      timeout  => "0",
      logoutput => true,
      require  => File["Put ${oneadmin_home}/remotes/hooks/eywa DIR"],
  }

  exec { "Set Testing SSH Key for EYWA-VR":
      command  => "sed -i \"s|@@__SSH_PUB_KEY__@@|$(cat /var/lib/one/.ssh/id_rsa.pub)|g\" ${oneadmin_home}/remotes/hooks/eywa/eywa_virtual_router.tmpl",
      user     => "root",
      timeout  => "0",
      logoutput => true,
      require  => Exec["Set Testing SSH Key for EYWA-VM"],
  }

  file { "Put ${oneadmin_home}/files DIR":
      path     => "${oneadmin_home}/files",
      owner    => "oneadmin",
      group    => "oneadmin",
      mode     => 0775,
      source   => "/vagrant/resources/puppet/files/eywa-files",
      ensure   => directory,
      replace  => true,
      recurse  => true,
      require  => Exec["Set Testing SSH Key for EYWA-VR"],
  }
  
  exec { "mkdir -p /var/log/one/templates":
      command  => "mkdir -p /var/log/one/templates && chown oneadmin:oneadmin /var/log/one/templates",
      creates  => "/var/log/one/templates",
      user     => "oneadmin",
      timeout  => "0",
      logoutput => true,
      require  => File["Put ${oneadmin_home}/files DIR"],
  }
  
  file { "Put ${oneadmin_home}/remotes/vmm/check_eywa_net.sh":
      path    => "${oneadmin_home}/remotes/vmm/check_eywa_net.sh",
      ensure  => present,
      owner   => "oneadmin",
      group   => "oneadmin",
      mode    => 0775,
      content => template("/vagrant/resources/puppet/templates/check_eywa_net.sh"),
      require => Exec["mkdir -p /var/log/one/templates"],
  }
  
  exec { "Backup ${oneadmin_home}/remotes/vmm/kvm/deploy":
      command  => "cp -a ${oneadmin_home}/remotes/vmm/kvm/deploy ${oneadmin_home}/remotes/vmm/kvm/deploy.bak",
      user     => "oneadmin",
      timeout  => "0",
      logoutput => true,
      unless   => "test ! -f ${oneadmin_home}/remotes/vmm/kvm/deploy.bak",
      require  => File["Put ${oneadmin_home}/remotes/vmm/check_eywa_net.sh"],
  }
  
  exec { "Add check_eywa_net.sh -> ${oneadmin_home}/remotes/vmm/kvm/deploy":
      command  => "sed -i '/^data/i source $(dirname \$0)/../check_eywa_net.sh' ${oneadmin_home}/remotes/vmm/kvm/deploy",
      user     => "oneadmin",
      timeout  => "0",
      logoutput => true,
      unless   => "grep -q check_eywa_net.sh ${oneadmin_home}/remotes/vmm/kvm/deploy",
      require  => Exec["Backup ${oneadmin_home}/remotes/vmm/kvm/deploy"],
  }
  
  file { "Put add-eywa-oned.conf":
      path    => "/home/vagrant/add-eywa-oned.conf",
      ensure  => present,
      owner   => "root",
      group   => "root",
      mode    => 0644,
      source  => "/vagrant/resources/puppet/files/add-eywa-oned.conf",
      require => Exec["Add check_eywa_net.sh -> ${oneadmin_home}/remotes/vmm/kvm/deploy"],
  }
  
  file { "Put add-eywa-oned.conf.sh":
      path    => "/home/vagrant/add-eywa-oned.conf.sh",
      ensure  => present,
      owner   => "root",
      group   => "root",
      mode    => 0775,
      source  => "/vagrant/resources/puppet/files/add-eywa-oned.conf.sh",
      require => File["Put add-eywa-oned.conf"],
  }
  
  exec { "Config oned.conf for EYWA":
      command  => "/home/vagrant/add-eywa-oned.conf.sh",
      user     => "root",
      timeout  => "0",
      logoutput => true,
      require  => File["Put add-eywa-oned.conf.sh"],
  }
  
  exec { "Restart OpenNebula Service":
      command  => "service opennebula restart",
      user     => "root",
      timeout  => "0",
      logoutput => true,
      require  => Exec["Config oned.conf for EYWA"],
  }
  
  package { "bind9":
      ensure   => installed,
      #ensure   => "1:9.9.5.dfsg-3",
  }
  
  package { "bind9-host":
      ensure   => installed,
      #ensure   => "1:9.9.5.dfsg-3",
  }
  
  package { "bind9utils":
      ensure   => installed,
      #ensure   => "1:9.9.5.dfsg-3",
  }
  
  file { "Put /var/lib/bind/test.org.zone":
      path    => "/var/lib/bind/test.org.zone",
      ensure  => present,
      owner   => "bind",
      group   => "bind",
      mode    => 0644,
      content => template("/vagrant/resources/puppet/templates/dns/bind/test.org.zone.erb"),
      require => [Package["bind9"], Package["bind9-host"], Package["bind9utils"]],
  }
  
  file { "Put /var/lib/bind/${ptr_head}.in-addr.arpa.zone":
      path    => "/var/lib/bind/${ptr_head}.in-addr.arpa.zone",
      ensure  => present,
      owner   => "bind",
      group   => "bind",
      mode    => 0644,
      content => template("/vagrant/resources/puppet/templates/dns/bind/in-addr.arpa.zone.erb"),
      require => [Package["bind9"], Package["bind9-host"], Package["bind9utils"]],
  }
  
  file { "Put /etc/bind/named.conf.local":
      path    => "/etc/bind/named.conf.local",
      ensure  => present,
      owner   => "root",
      group   => "bind",
      mode    => 0644,
      content => template("/vagrant/resources/puppet/templates/dns/named.conf.local.erb"),
      require => File["Put /var/lib/bind/${ptr_head}.in-addr.arpa.zone"],
  }
  
  file { "Put /etc/bind/named.conf.options":
      path    => "/etc/bind/named.conf.options",
      ensure  => present,
      owner   => "root",
      group   => "bind",
      mode    => 0644,
      content => template("/vagrant/resources/puppet/templates/dns/named.conf.options.erb"),
      require => File["Put /etc/bind/named.conf.local"],
  }
  
  exec { "Restart DNS(Bind9) Service":
      command  => "service bind9 restart",
      user     => "root",
      timeout  => "0",
      logoutput => true,
      require  => File["Put /etc/bind/named.conf.options"],
  }
  
  exec { "Set DNS Nameserver":
      command => "sed -i '1s/^/nameserver 127.0.0.1\\n/' /etc/resolv.conf",
      user    => "root",
      timeout => "0",
      require => Exec["Restart DNS(Bind9) Service"],
      before  => Exec["Sync: onehost sync -f"],
  }
}

exec { "Sync: onehost sync -f":
    provider => shell,
    command  => "su -l oneadmin -c \"ssh oneadmin@master 'onehost sync -f'\"",
    user     => "root",
    timeout  => "0",
    logoutput => true,
}

