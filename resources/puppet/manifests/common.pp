####################################################

include 'apt'

### Export Env: Global %PATH for "Exec"
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin" ] }

exec { "Add apt-key":
    command  => "wget -q -O- http://downloads.opennebula.org/repo/Ubuntu/repo.key | apt-key add -",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    #require => File[""],
}

file { "Add sources.list":
    path    => "/etc/apt/sources.list.d/opennebula.list",
    ensure  => present,
    owner    => "root",
    group    => "root",
    content => "deb http://downloads.opennebula.org/repo/Ubuntu/14.04 stable opennebula",
    require => Exec["Add apt-key"],
}

exec { "Apt-get Uodate":
    command  => "apt-get update",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require => File["Add sources.list"],
}

