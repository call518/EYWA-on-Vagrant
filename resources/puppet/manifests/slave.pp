####################################################

include 'apt'

### Export Env: Global %PATH for "Exec"
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin" ] }

$oneadmin_home = "/var/lib/one"

package { "arptables":
    ensure   => installed,
}

package { "nfs-common":
    ensure   => installed,
}

package { "opennebula-node":
    ensure   => installed,
}

package { "qemu-system":
    ensure   => installed,
    require  => Package["opennebula-node"],
}

package { "bridge-utils":
    ensure   => installed,
}

service { "libvirt-bin":
    ensure  => "running",
    enable  => "true",
    require => [Package["opennebula-node"], Package["qemu-system"]],
}

file { "Set eth1.cfg":
    path    => "/etc/network/interfaces.d/eth1.cfg",
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 0644,
    content => template("/vagrant/resources/puppet/templates/eth1.cfg.erb"),
    require => [Package["nfs-common"], Package["opennebula-node"], Package["bridge-utils"]],
}

exec { "Enable eth1":
    command  => "ifup eth1",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    unless   => "ifconfig eth1 2> /dev/null | grep -q UP",
    require  => File["Set eth1.cfg"],
}

#file { "Set eth2.cfg":
#    path    => "/etc/network/interfaces.d/eth2.cfg",
#    ensure  => present,
#    owner   => "root",
#    group   => "root",
#    mode    => 0644,
#    content => template("/vagrant/resources/puppet/templates/eth2.cfg.erb"),
#    require => Exec["Enable eth1"],
#}

#exec { "Enable eth2":
#    command  => "ifup eth2",
#    user     => "root",
#    timeout  => "0",
#    logoutput => true,
#    unless   => "ifconfig eth2 2> /dev/null | grep -q UP",
#    require  => File["Set eth2.cfg"],
#}

if $hostname =~ /^master/ {
  file { "Set VSe.cfg":
      path    => "/etc/network/interfaces.d/VSe.cfg",
      ensure  => present,
      owner   => "root",
      group   => "root",
      mode    => 0644,
      content => template("/vagrant/resources/puppet/templates/VSe-master.cfg.erb"),
      require => Exec["Enable eth1"],
      #require => Exec["Enable eth2"],
  }
} else {
  file { "Set VSe.cfg":
      path    => "/etc/network/interfaces.d/VSe.cfg",
      ensure  => present,
      owner   => "root",
      group   => "root",
      mode    => 0644,
      content => template("/vagrant/resources/puppet/templates/VSe-slave.cfg.erb"),
      require => Exec["Enable eth1"],
  }
}

exec { "Enable VSe":
    command  => "ifup VSe",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    unless   => "ifconfig VSe 2> /dev/null | grep -q UP",
    require  => File["Set VSe.cfg"],
}

exec { "Disable virbr0":
    command  => "sleep 10; virsh net-destroy default && virsh net-autostart default --disable",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    onlyif   => "ifconfig virbr0 2> /dev/null > /dev/null",
    #require  => Exec["Static ARP Table for VSe"],
    require  => Exec["Enable VSe"],
}

if $hostname =~ /^slave-[0-9]+/ {
    file { "Put .ssh DIR":
        path     => "${oneadmin_home}/.ssh",
        owner    => "oneadmin",
        group    => "oneadmin",
        mode     => 0644,
        source   => "/vagrant/resources/puppet/files/.ssh",
        ensure   => directory,
        replace  => true,
        recurse  => true,
        require  => Exec["Disable virbr0"],
    }
    exec { "Permission Private SSH-key":
        command  => "chown oneadmin:oneadmin ${oneadmin_home}/.ssh/* && chmod 644 ${oneadmin_home}/.ssh/* && chmod 600 ${oneadmin_home}/.ssh/id_rsa",
        cwd      => "${oneadmin_home}",
        user     => "oneadmin",
        timeout  => "0",
        logoutput => true,
        require  => File["Put .ssh DIR"],
    }
    exec { "Add /etc/fstab":
        command  => "echo 'master:/var/lib/one/datastores /var/lib/one/datastores nfs soft,intr,rsize=8192,wsize=8192,noauto' >> /etc/fstab",
        user     => "root",
        timeout  => "0",
        logoutput => true,
        unless   => "df | grep -q '^master:/var/lib/one/datastores'",
        require  => Exec["Permission Private SSH-key"],
    }
    #file { "Create DIR /var/lib/one/datastores":
    #    path     => "/var/lib/one/datastores",
    #    owner    => "oneadmin",
    #    group    => "oneadmin",
    #    mode     => 0755,
    #    ensure   => directory,
    #    recurse  => true,
    #    require  => Exec["Add /etc/fstab"],
    #}
    exec { "Create DIR /var/lib/one/datastores":
        command  => "mkdir -p /var/lib/one/datastores && chown oneadmin:oneadmin /var/lib/one/datastores && chmod 0755 /var/lib/one/datastores",
        creates  => "/var/lib/one/datastores",
        user     => "oneadmin",
        group    => "oneadmin",
        timeout  => "0",
        logoutput => true,
        require  => Exec["Add /etc/fstab"],
    }
    exec { "Mount datastore":
        provider => shell,
        #command  => "mount /var/lib/one/datastores",
        command  => "while ! df | grep -q '^master:/var/lib/one/datastores'; do mount /var/lib/one/datastores; sleep 5; done",
        user     => "root",
        timeout  => "0",
        logoutput => true,
        unless   => "df | grep -q '^master:/var/lib/one/datastores'",
        require  => Exec["Create DIR /var/lib/one/datastores"],
    }
    exec { "Set Ownership for /var/lib/one/datastores":
        command  => "chown -R oneadmin:oneadmin /var/lib/one/datastores && chmod -R 775 /var/lib/one/datastores",
        user     => "root",
        timeout  => "0",
        logoutput => true,
        require  => Exec["Mount datastore"],
        before   => File["Put .ssh DIR for root"],
    }
}

file { "Put .ssh DIR for root":
    path     => "/root/.ssh",
    owner    => "root",
    group    => "root",
    mode     => 0644,
    source   => "/vagrant/resources/puppet/files/.ssh",
    ensure   => directory,
    replace  => true,
    recurse  => true,
    require  => Exec["Disable virbr0"],
}

exec { "Permission Private SSH-key for root":
    command  => "chown root:root /root/.ssh/* && chmod 644 /root/.ssh/* && chmod 600 /root/.ssh/id_rsa",
    cwd      => "/root",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require  => File["Put .ssh DIR for root"],
}

file { "Config Libvirt/QEMU":
    path    => "/etc/libvirt/qemu.conf",
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 0644,
    content => template("/vagrant/resources/puppet/templates/libvirt-qemu.conf.erb"),
    notify  => Service["libvirt-bin"],
    require => Exec["Permission Private SSH-key for root"],
}

exec { "Update Apparmor":
    command  => "sed -i '/change_profile/a \\  /usr/libexec/libvirt_iohelper Uxr,' /etc/apparmor.d/usr.sbin.libvirtd && service apparmor reload",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    unless   => "grep -q '/usr/libexec/libvirt_iohelper Uxr,' /etc/apparmor.d/usr.sbin.libvirtd",
    require  => File["Config Libvirt/QEMU"],
}

exec { "Add ONE Node":
    #command  => "su -l oneadmin -c \"ssh oneadmin@master 'onehost create $hostname -i kvm -v kvm -n ebtables'\"",
    command  => "su -l oneadmin -c \"ssh oneadmin@master 'onehost create $hostname -i kvm -v kvm -n dummy'\"",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    unless   => "su -l oneadmin -c \"ssh oneadmin@master 'onehost list'\" | grep -q $hostname",
    require  => Exec["Update Apparmor"],
}

