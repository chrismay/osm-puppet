class hudson{
user { 'hudson':
    shell => '/bin/bash',
    home => '/var/hudson',
    uid => '1001',
    ensure => 'present',
    gid => '1002',
    groups => ['adm','admin',],
    comment => 'Hudson user,,,'
}

group {"hudson":
    gid=>1002
}

file{["/var/hudson","/var/hudson/.ssh"]: ensure=>directory, owner=>hudson}

}
include hudson
