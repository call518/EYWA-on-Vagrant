####################################################

include 'apt'

### Export Env: Global %PATH for "Exec"
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin" ] }

package { "nfs-common":
    ensure   => installed,
}

package { "opennebula-node":
    ensure   => installed,
}

package { "bridge-utils":
    ensure   => installed,
}

exec { "Disable virbr0":
    command  => "virsh net-destroy default && virsh net-autostart default --disable",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    onlyif   => "ifconfig virbr0 2> /dev/null > /dev/null",
    require  => [Package["nfs-common"], Package["opennebula-node"], Package["bridge-utils"]],
}

file { "Set br0.cfg":
    path    => "/etc/network/interfaces.d/br0.cfg",
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 0644,
    content => template("/vagrant/resources/puppet/templates/br0.cfg.erb"),
    require  => Exec["Disable virbr0"],
}

exec { "Up br0":
    command  => "ip link set up eth1 && ifup br0",
    user     => "oneadmin",
    timeout  => "0",
    logoutput => true,
    unless   => "ifconfig br0 2> /dev/null",
    require  => File["Set br0"],
}

