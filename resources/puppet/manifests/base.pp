#### Base (Common pp) #########

include 'apt'

### Export Env: Global %PATH for "Exec"
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin" ] }

exec { "Apt-get Update":
    command  => "apt-get update",
    user     => "root",
    timeout  => "0",
    logoutput => true,
}

#package { "git":
#    ensure => "installed"
#    require => Exec["Apt-get Update"],
#}

#package { "unzip":
#    ensure => "installed"
#    require => Exec["Apt-get Update"],
#}

#package { "dos2unix":
#    ensure   => installed,
#    require => Exec["Apt-get Update"],
#}

#package { "expect":
#    ensure   => installed,
#    require => Exec["Apt-get Update"],
#}

#package { "sshpass":
#    ensure   => installed,
#    require => Exec["Apt-get Update"],
#}

case $operatingsystem {
    debian, ubuntu: { $vim_pkg = "vim" }
    centos, redhat, fedora: { $vim_pkg = "vim-enhanced" }
    default: { fail("Unrecognized operating system for webserver") }
}

case $operatingsystem {
    debian, ubuntu: { $vimrc = "/etc/vim/vimrc" }
    centos, redhat, fedora: { $vimrc = "/etc/vimrc" }
    default: { fail("Unrecognized operating system for webserver") }
}

package { $vim_pkg:
    ensure => "installed"
}

exec { "echo 'set bg=dark' >> $vimrc":
    user    => "root",
    timeout => "0",
    require => Package[ $vim_pkg ],
}

exec { "echo 'set ts=4' >> $vimrc":
    user    => "root",
    timeout => "0",
    require => Package[ $vim_pkg ],
}

$hosts = hiera("hosts")

file { "/etc/hosts":
    ensure => file,
    owner => "root",
    group => "root",
    content => template("/vagrant/resources/puppet/templates/hosts.erb")
}

exec { "Set Hostname":
    command  => "hostname -F /etc/hostname",
    user     => "root",
    timeout  => "0",
    unless   => "test `hostname` = `cat /etc/hostname`",
    require => File["/etc/hosts"],
}

exec { "cp /usr/share/zoneinfo/Asia/Seoul /etc/localtime":
    user    => "root",
    timeout => "0",
}

