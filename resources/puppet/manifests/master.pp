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

package { "virt-manager":
    ensure   => installed,
    require  => Package["opennebula"],
}

package { "opennebula-sunstone":
    ensure   => installed,
}

package { "mysql-server":
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
    mode    => 0644,
    source  => "/vagrant/resources/puppet/files/nfs-exports",
    notify  => Service["nfs-kernel-server"],
    require => Package["nfs-kernel-server"],
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

file { "Put config-one-env.sh":
    path    => "/home/vagrant/config-one-env.sh",
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 0744,
    content => template("/vagrant/resources/puppet/templates/config-one-env.sh.erb"),
    require  => Exec["Restart OpenNebula Service"],
}

file { "Put set-oneadmin-pw.sh":
    path    => "/home/vagrant/set-oneadmin-pw.sh",
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 0744,
    content => template("/vagrant/resources/puppet/templates/set-oneadmin-pw.sh.erb"),
    require  => File["Put config-one-env.sh"],
}

exec { "Run set-oneadmin-pw.sh":
    command  => "/home/vagrant/set-oneadmin-pw.sh",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require  => File["Put set-oneadmin-pw.sh"],
}

########## Set VNC Server ##########################

exec { "Install GNOME Desktop (1)":
    provider => shell,
    environment => ["DEBIAN_FRONTEND=noninteractive"],
    command  => "apt-get -q -y --force-yes -o DPkg::Options::=--force-confold install --no-install-recommends ubuntu-gnome-desktop",
    user     => "root",
    timeout  => "0",
    #logoutput => true,
}

exec { "Install GNOME Desktop (2)":
    provider => shell,
    environment => ["DEBIAN_FRONTEND=noninteractive"],
    command  => "apt-get -q -y --force-yes -o DPkg::Options::=--force-confold install gnome-panel gnome-settings-daemon metacity nautilus gnome-terminal",
    user     => "root",
    timeout  => "0",
    #logoutput => true,
    require  => Exec["Install GNOME Desktop (1)"],
}

package { "vnc4server":
    ensure   => installed,
}

package { "expect":
    ensure   => installed,
}

file { "Put .vnc DIR":
    path     => "/root/.vnc",
    owner    => "root",
    group    => "root",
    mode     => 0755,
    ensure   => directory,
    replace  => true,
    recurse  => true,
    require  => [Exec["Install GNOME Desktop (2)"], Package["vnc4server"], Package["expect"]],
}

file { "Put /tmp/vnc-passwd.txt":
    path    => "/tmp/vnc-passwd.txt",
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 0644,
    content => template("/vagrant/resources/puppet/templates/vnc-passwd.txt.erb"),
    require  => File["Put .vnc DIR"],
}

exec { "Set vncpasswd for root":
    provider => shell,
    command  => "vncpasswd /root/.vnc/passwd < /tmp/vnc-passwd.txt && chmod 600 /root/.vnc/passwd && rm /tmp/vnc-passwd.txt",
    creates  => "/root/.vnc/passwd",
    cwd      => "/root",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require  => File["Put /tmp/vnc-passwd.txt"],
}

file { "Put VNC xstartup":
    path    => "/root/.vnc/xstartup",
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 0744,
    source => "/vagrant/resources/puppet/files/vnc-xstartup",
    require  => Exec["Set vncpasswd for root"],
}

file { "Put vncserver Init-Script":
    path    => "/etc/init.d/vncserver",
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 0755,
    content => template("/vagrant/resources/puppet/templates/init-vncserver.erb"),
    require  => File["Put VNC xstartup"],
}

exec { "Add Service - vncserver":
    command  => "update-rc.d vncserver defaults",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require  => File["Put vncserver Init-Script"],
}

exec { "Start vncserver Service":
    command  => "service vncserver start",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    unless   => "lsof -ni:5900",
    require  => Exec["Add Service - vncserver"],
}

####################################################
