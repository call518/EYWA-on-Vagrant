####################################################

include 'apt'

### Export Env: Global %PATH for "Exec"
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin" ] }

$oneadmin_home = "/var/lib/one"

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

file { "Set br0.cfg":
    path    => "/etc/network/interfaces.d/br0.cfg",
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 0644,
    content => template("/vagrant/resources/puppet/templates/br0.cfg.erb"),
    require => Exec["Enable eth1"],
}

exec { "Enable br0":
    command  => "ifup br0",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    unless   => "ifconfig br0 2> /dev/null | grep -q UP",
    require  => File["Set br0.cfg"],
}

exec { "Disable virbr0":
    command  => "sleep 10; virsh net-destroy default && virsh net-autostart default --disable",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    onlyif   => "ifconfig virbr0 2> /dev/null > /dev/null",
    require  => Exec["Enable br0"],
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
    file { "Create DIR /var/lib/one/datastores":
        path     => "/var/lib/one/datastores",
        owner    => "oneadmin",
        group    => "oneadmin",
        mode     => 0755,
        ensure   => directory,
        recurse  => true,
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
        require  => File["Create DIR /var/lib/one/datastores"],
        before   => File["Config Libvirt/QEMU"],
    }
}

file { "Config Libvirt/QEMU":
    path    => "/etc/libvirt/qemu.conf",
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 0644,
    content => template("/vagrant/resources/puppet/templates/libvirt-qemu.conf.erb"),
    notify  => Service["libvirt-bin"],
    require => Exec["Disable virbr0"],
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
    command  => "su -l oneadmin -c \"ssh oneadmin@master 'onehost create $hostname -i kvm -v kvm -n ebtables'\"",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    unless   => "su -l oneadmin -c \"ssh oneadmin@master 'onehost list'\" | grep -q $hostname",
    require  => File["Config Libvirt/QEMU"],
}

