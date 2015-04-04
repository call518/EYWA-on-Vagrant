####################################################

include 'apt'

### Export Env: Global %PATH for "Exec"
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin" ] }

$oneadmin_home = "/var/lib/one"

package { "nfs-kernel-server":
    ensure   => installed,
}

package { "opennebula":
    #ensure   => installed,
    ensure   => "4.6.2-1",
}

package { "opennebula-sunstone":
    #ensure   => installed,
    ensure   => "4.6.2-1",
}

package { "mysql-server":
    ensure   => installed,
}

exec { "Set MySQL root Password":
    command  => "mysqladmin -uroot password ${oneadmin_pw}",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    onlyif   => "test -f /root/.installed.mysql",
    require  => Package["mysql-server"],
}

exec { "Create opennebula Database":
    command  => "mysql -uroot -p${oneadmin_pw} -e 'create database opennebula' && touch /root/.installed.mysql",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    onlyif   => "test -f /root/.installed.mysql",
    notify  => Service["opennebula"],
    require  => Exec["Set MySQL root Password"],
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

#exec { "Set SSH authorized_keys":
#    command  => "cp ${oneadmin_home}/.ssh/id_rsa.pub ${oneadmin_home}/.ssh/authorized_keys",
#    cwd      => "${oneadmin_home}",
#    user     => "oneadmin",
#    timeout  => "0",
#    logoutput => true,
#    require  => File["Export NFS"],
#}

file { "Put .ssh DIR":
    path     => "${oneadmin_home}/.ssh",
    owner    => "oneadmin",
    group    => "oneadmin",
    mode     => 0644,
    source   => "/vagrant/resources/puppet/files/.ssh",
    ensure   => directory,
    replace  => true,
    recurse  => true,
    require  => File["Export NFS"],
}

exec { "Permission Private SSH-key":
    command  => "chown oneadmin:oneadmin ${oneadmin_home}/.ssh/* && chmod 644 ${oneadmin_home}/.ssh/* && chmod 600 ${oneadmin_home}/.ssh/id_rsa",
    cwd      => "${oneadmin_home}",
    user     => "oneadmin",
    timeout  => "0",
    logoutput => true,
    require  => File["Put .ssh DIR"],
}

#exec { "Upload .ssh DIR":
#    command  => "rm -rf /vagrant/.ssh; cp -a ${oneadmin_home}/.ssh/ /vagrant/",
#    user     => "root",
#    timeout  => "0",
#    logoutput => true,
#    require  => Exec["Permission Private SSH-key"],
#}
#
#file { "Set SSH Client Options":
#    path    => "${oneadmin_home}/.ssh/config",
#    ensure  => present,
#    owner   => "oneadmin",
#    group   => "oneadmin",
#    source  => "/vagrant/resources/puppet/files/one-ssh-config",
#    require => Exec["Upload .ssh DIR"],
#}

file { "Config oned.conf":
    path    => "/etc/one/oned.conf",
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 0644,
    content => template("/vagrant/resources/puppet/templates/oned.conf.erb"),
    notify  => Service["opennebula"],
    require => [Exec["Create opennebula Database"], Exec["Permission Private SSH-key"]],
}

file { "Put config-one-env.sh":
    path    => "/home/vagrant/config-one-env.sh",
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 0700,
    content => template("/vagrant/resources/puppet/templates/config-one-env.sh.erb"),
    require  => File["Config oned.conf"],
}

exec { "Run config-one-env.sh":
    command  => "/home/vagrant/config-one-env.sh",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require  => File["Put config-one-env.sh"],
}
