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
    command  => "/eywa_schema.sql",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require  => File["Put eywa_schema.sql"],
}

