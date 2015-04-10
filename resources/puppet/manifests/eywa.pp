####################################################

include 'apt'

### Export Env: Global %PATH for "Exec"
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin" ] }

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

