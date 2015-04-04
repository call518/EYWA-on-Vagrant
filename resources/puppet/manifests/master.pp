####################################################

include 'apt'

### Export Env: Global %PATH for "Exec"
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin" ] }

package { "nfs-kernel-server":
    ensure   => installed,
}

package { "opennebula":
    ensure   => installed,
}

package { "opennebula-sunstone":
    ensure   => installed,
}

service { "nfs-kernel-server":
    ensure  => "running",
    enable  => "true",
    require => Package["nfs-kernel-server"],
}

service { "opennebula":
    ensure  => "running",
    enable  => "true",
    require => Package["opennebula"],
}

service { "opennebula-sunstone":
    ensure  => "running",
    enable  => "true",
    require => Package["opennebula-sunstone"],
}

file { "Config sunstone.conf":
    path    => "/etc/one/sunstone-server.conf",
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 0644,
    content => template("/vagrant/resources/puppet/templates/sunstone-server.conf.erb"),
    notify  => Service["opennebula-sunstone"],
    require => Package["opennebula-sunstone"],
}

file { "Export NFS":
    path    => "/etc/exports",
    ensure  => present,
    owner   => "root",
    group   => "root",
    source  => "/vagrant/resources/puppet/files/nfs-exports",
    notify  => Service["nfs-kernel-server"],
    require => Package["nfs-kernel-server"],
}

$one_home = "/var/lib/one"

exec { "Set SSH authorized_keys":
    command  => "cp $one_home/.ssh/id_rsa.pub $one_home/.ssh/authorized_keys",
    cwd      => "$one_home",
    user     => "oneadmin",
    timeout  => "0",
    logoutput => true,
    require  => File["Export NFS"],
}

file { "Set SSH Client Options":
    path    => "$one_home/.ssh/config",
    ensure  => present,
    owner   => "oneadmin",
    group   => "oneadmin",
    source  => "/vagrant/resources/puppet/files/one-ssh-config",
    require => Exec["Set SSH authorized_keys"],
}

