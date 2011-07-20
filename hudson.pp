class hudson{
user { 'hudson':
    shell => '/bin/bash',
    home => '/var/hudson',
    uid => '1001',
    ensure => 'present',
    gid => '1001',
    groups => ['adm','admin',],
    comment => 'Hudson user,,,'
}

file{["/var/hudson","/var/hudson/.ssh"]: ensure=>directory, owner=>hudson}

}
include hudson
