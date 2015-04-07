####################################################

include 'apt'

### Export Env: Global %PATH for "Exec"
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin" ] }

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

file { "Put /tmp/vnc-passwd.txt":
    path    => "/tmp/vnc-passwd.txt",
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 0644,
    content => template("/vagrant/resources/puppet/templates/vnc-passwd.txt.erb"),
    require  => Exec["Install GNOME Desktop (2)"],
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

exec { "Create DIR - /root/.config/nautilus":
    provider => shell,
    command  => "mkdir -p /root/.config/nautilus",
    creates  => "/root/.config/nautilus",
    cwd      => "/root",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require  => Exec["Create DIR - /root/.vnc"],
}

exec { "Set vncpasswd for root":
    provider => shell,
    command  => "vncpasswd /root/.vnc/passwd < /tmp/vnc-passwd.txt && chmod 600 /root/.vnc/passwd && rm /tmp/vnc-passwd.txt",
    creates  => "/root/.vnc/passwd",
    cwd      => "/root",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require  => Exec["Create DIR - /root/.config/nautilus"],
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

file { "Put /root/.config/nautilus DIR":
    path     => "/root/.config/nautilus",
    owner    => "root",
    group    => "root",
    mode     => 0755,
    ensure   => directory,
    replace  => true,
    recurse  => true,
    require  => Exec["Add Service - vncserver"],
}

exec { "Start vncserver Service":
    command  => "service vncserver start",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    unless   => "lsof -ni:5900",
    require  => File["Put /root/.config/nautilus DIR"],
}

