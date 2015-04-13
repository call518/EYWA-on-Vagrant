####################################################

include 'apt'

### Export Env: Global %PATH for "Exec"
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin" ] }

$oneadmin_home = "/var/lib/one"

file { "Put eywa_schema.sql":
    path    => "/home/vagrant/eywa_schema.sql",
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 0644,
    source  => "/vagrant/resources/puppet/files/eywa_schema.sql",
    #require => Package["nfs-kernel-server"],
}

exec { "Create eywa DB":
    command  => "mysql -uroot -p${oneadmin_pw} -e 'create database eywa'",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    unless   => "mysql -uroot -p${oneadmin_pw} -e 'use eywa'",
    require  => File["Put eywa_schema.sql"],
}

exec { "Create eywa Schema & Env.":
    command  => "mysql -uroot -p${oneadmin_pw} eywa < /home/vagrant/eywa_schema.sql",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    unless   => "mysql -uroot -p${oneadmin_pw} -e 'select * from eywa.vm_info'",
    require  => Exec["Create eywa DB"],
}

#exec { "Generate Multicast Address Pool":
#    command  => "for i in `seq 0 15`; do for j in `seq 0 255`; do mysql -uroot -p${oneadmin_pw} -e \"insert into eywa.mc_address values ('','239.0.$i.$j','')\"; done; done",
#    user     => "root",
#    timeout  => "0",
#    logoutput => true,
#    unless   => "mysql -uroot -p${oneadmin_pw} -e 'select * from eywa.vm_info'",
#    require  => Exec["Create eywa Schema & Env."],
#}

file { "Put hooks/eywa DIR":
    path     => "${oneadmin_home}/remotes/hooks/eywa",
    owner    => "oneadmin",
    group    => "oneadmin",
    mode     => 0775,
    source   => "/vagrant/resources/puppet/files/eywa",
    ensure   => directory,
    replace  => true,
    recurse  => true,
    require  => Exec["Create eywa Schema & Env."],
}

file { "Put xpath.rb":
    path    => "${oneadmin_home}/remotes/datastore/xpath.rb",
    ensure  => present,
    owner   => "oneadmin",
    group   => "oneadmin",
    mode    => 0775,
    source  => "/vagrant/resources/puppet/files/xpath.rb",
    require => File["Put hooks/eywa DIR"],
}

file { "Config oned.conf for EYWA":
    path    => "/etc/one/oned.conf",
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 0644,
    content => template("/vagrant/resources/puppet/templates/oned.conf-eywa.erb"),
    require => File["Put xpath.rb"],
}

exec { "Restart OpenNebula Service":
    command  => "service opennebula restart",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require  => File["Config oned.conf for EYWA"],
}

package { "bind9":
    #ensure   => installed,
    ensure   => "1:9.9.5.dfsg-3",
}

package { "bind9-host":
    #ensure   => installed,
    ensure   => "1:9.9.5.dfsg-3",
}

package { "bind9utils":
    #ensure   => installed,
    ensure   => "1:9.9.5.dfsg-3",
}

file { "Put /var/lib/bind/test.org.zone":
    path    => "/var/lib/bind/test.org.zone.erb",
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
    user     => "root",
    timeout  => "0",
    require => Exec["Restart DNS(Bind9) Service"],
}

