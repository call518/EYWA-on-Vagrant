####################################################

include 'apt'

### Export Env: Global %PATH for "Exec"
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin" ] }

exec { "Install Xfce4 Desktop":
    provider => shell,
    environment => ["DEBIAN_FRONTEND=noninteractive"],
    command  => "apt-get -q -y --force-yes -o DPkg::Options::=--force-confold install xfce4 xfce4-goodies",
    user     => "root",
    timeout  => "0",
    #logoutput => true,
}

package { "vnc4server":
    ensure   => installed,
}

file { "Put /tmp/vnc-passwd.txt":
    path    => "/tmp/vnc-passwd.txt",
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 0644,
    content => template("/vagrant/resources/puppet/templates/vnc-passwd.txt.erb"),
    require  => [Exec["Install Xfce4 Desktop"], Package["vnc4server"]],
}

exec { "Create DIR - /root/.vnc":
    provider => shell,
    command  => "mkdir /root/.vnc",
    creates  => "/root/.vnc",
    cwd      => "/root",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require  => File["Put /tmp/vnc-passwd.txt"],
}

exec { "Create DIR - /root/.config":
    provider => shell,
    command  => "mkdir /root/.config",
    creates  => "/root/.vnc",
    cwd      => "/root",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require  => Exec["Create DIR - /root/.vnc"],
}

file { "Put Xfce4 Config DIR":
    path     => "/root/.config/xfce4",
    ensure   => present,
    owner    => "root",
    group    => "root",
    mode     => 0755,
    replace  => true,
    recurse  => true,
    source   => "/vagrant/resources/puppet/files/root-xfce4",
    require  => Exec["Create DIR - /root/.config"],
}

exec { "Set vncpasswd for root":
    provider => shell,
    command  => "vncpasswd /root/.vnc/passwd < /tmp/vnc-passwd.txt && chmod 600 /root/.vnc/passwd && rm /tmp/vnc-passwd.txt",
    creates  => "/root/.vnc/passwd",
    cwd      => "/root",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require  => File["Put Xfce4 Config DIR"],
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

