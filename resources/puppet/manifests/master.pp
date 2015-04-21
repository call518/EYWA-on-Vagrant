####################################################

include 'apt'

### Export Env: Global %PATH for "Exec"
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin" ] }

$oneadmin_home = "/var/lib/one"

package { "nfs-kernel-server":
    ensure   => installed,
}

package { "opennebula":
    ensure   => installed,
}

package { "opennebula-sunstone":
    ensure   => installed,
}

package { "mysql-server":
    #ensure   => installed,
    ensure   => "5.5.41-0ubuntu0.14.04.1",
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

service { "mysql":
    ensure  => "running",
    enable  => "true",
    require => Package["mysql-server"],
}

exec { "Set MySQL root Password":
    command  => "mysqladmin -uroot password ${oneadmin_pw}",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    onlyif   => "test ! -f /root/.installed.mysql",
    require  => [Package["opennebula"], Package["mysql-server"]],
}

exec { "Create opennebula Database":
    command  => "mysql -uroot -p${oneadmin_pw} -e 'create database opennebula' && touch /root/.installed.mysql",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    onlyif   => "test ! -f /root/.installed.mysql",
    notify   => Service["opennebula"],
    require  => Exec["Set MySQL root Password"],
}

file { "Config my.cnf":
    path    => "/etc/mysql/my.cnf",
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 0644,
    content => template("/vagrant/resources/puppet/templates/my.cnf.erb"),
    notify  => Service["mysql"],
    require => Exec["Create opennebula Database"],
}

file { "Config sunstone.conf":
    path    => "/etc/one/sunstone-server.conf",
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 0644,
    content => template("/vagrant/resources/puppet/templates/sunstone-server.conf.erb"),
    notify  => Service["opennebula-sunstone"],
    require => [Package["opennebula-sunstone"], File["Config my.cnf"]],
}

file { "Export NFS":
    path    => "/etc/exports",
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 0644,
    source  => "/vagrant/resources/puppet/files/nfs-exports",
    notify  => Service["nfs-kernel-server"],
    require => [Package["nfs-kernel-server"], File["Config sunstone.conf"]],
}

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

exec { "Restart OpenNebula Service":
    command  => "service opennebula restart",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require  => File["Config oned.conf"],
}

file { "Put set-oneadmin-pw.sh":
    path    => "/home/vagrant/set-oneadmin-pw.sh",
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 0744,
    content => template("/vagrant/resources/puppet/templates/set-oneadmin-pw.sh.erb"),
    require  => Exec["Restart OpenNebula Service"],
}

#exec { "dos2unix set-oneadmin-pw.sh":
#    command  => "dos2unix /home/vagrant/set-oneadmin-pw.sh",
#    user     => "root",
#    timeout  => "0",
#    logoutput => true,
#    require  => File["Put set-oneadmin-pw.sh"],
#}

exec { "Run set-oneadmin-pw.sh":
    command  => "/home/vagrant/set-oneadmin-pw.sh",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    #require  => Exec["dos2unix set-oneadmin-pw.sh"],
    require  => File["Put set-oneadmin-pw.sh"],
}

exec { "=== Waiting.... Downloading Template-Image... ===":
    command  => "echo '=== Waiting.... Downloading Template-Image... ==='",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require  => Exec["Run set-oneadmin-pw.sh"],
}

#exec { "Download Ubuntu-14.04.qcow2.gz":
#    command  => "wget 'https://onedrive.live.com/download?resid=28f8f701dc29e4b9%2110218' -O /usr/local/src/Ubuntu-14.04.qcow2.gz",
#    creates  => "/usr/local/src/Ubuntu-14.04.qcow2.gz",
#    user     => "root",
#    timeout  => "0",
#    #logoutput => true,
#    require  => Exec["=== Waiting.... Downloading Template-Image... ==="],
#}

exec { "Download EYWA-Virtual-Router.qcow2.gz":
    command  => "wget 'https://onedrive.live.com/download?resid=28f8f701dc29e4b9%2110208' -O /usr/local/src/EYWA-Virtual-Router.qcow2.gz",
    creates  => "/usr/local/src/EYWA-Virtual-Router.qcow2.gz",
    user     => "root",
    timeout  => "0",
    #logoutput => true,
    #require  => Exec["Download Ubuntu-14.04.qcow2.gz"],
    require  => Exec["=== Waiting.... Downloading Template-Image... ==="],
}

exec { "Download Ubuntu12.04_64.qcow2.gz":
    command  => "wget 'https://onedrive.live.com/download?resid=28f8f701dc29e4b9%2110206' -O /usr/local/src/Ubuntu12.04_64.qcow2.gz",
    creates  => "/usr/local/src/Ubuntu12.04_64.qcow2.gz",
    user     => "root",
    timeout  => "0",
    #logoutput => true,
    require  => Exec["Download EYWA-Virtual-Router.qcow2.gz"],
}

file { "Put one-public-net.tmpl":
    path    => "/home/vagrant/one-public-net.tmpl",
    ensure  => present,
    owner   => "root",
    group   => "oneadmin",
    mode    => 0744,
    source => "/vagrant/resources/puppet/files/one-public-net.tmpl",
    require  => Exec["Download Ubuntu12.04_64.qcow2.gz"],
}

file { "Put default.template":
    path    => "/home/vagrant/default.template",
    ensure  => present,
    owner   => "root",
    group   => "oneadmin",
    mode    => 0744,
    content => template("/vagrant/resources/puppet/templates/default.template.erb"),
    require  => File["Put one-public-net.tmpl"],
}

exec { "Set SSH_PUB_KEY in default.template":
    command  => "sed -i \"s|@@__SSH_PUB_KEY__@@|$(cat /var/lib/one/.ssh/id_rsa.pub)|g\" /home/vagrant/default.template",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require  => File["Put default.template"],
}

file { "Put config-one-env.sh":
    path    => "/home/vagrant/config-one-env.sh",
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 0744,
    content => template("/vagrant/resources/puppet/templates/config-one-env.sh.erb"),
    require  => Exec["Set SSH_PUB_KEY in default.template"],
}

exec { "Run config-one-env.sh":
    command  => "/home/vagrant/config-one-env.sh",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require  => File["Put config-one-env.sh"],
}

