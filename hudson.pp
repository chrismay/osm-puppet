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

ssh_authorized_key{"hudson@bob":
    key=>"AAAAB3NzaC1yc2EAAAABIwAAAQEAxXoZHNd6A/CmfR2uPM9YvgE9P4dEfkL+hMNXbPcGp8B82eJ/LtPgDh3M1BIGoXjZAgMUwafdGcCcF4rCVxjAluc7v9wzwIgALR9ILL+JJWxqUdVzZtES0nuk3NI55cO6Z/YZIYXpxdYxWY7nUmKSHuf3iePpspFdL7K4houQIqnkfalUybhwZ7sjaQRbBMsIQlgLwKBWnbp1eGKq1VRRs6q+FwNcqhTsLhfQBAU8pKTwt2qCWh430kZTUv7x8cZcbyiur09SWotjmhON742ke+LEhUxVvfZykO2LU8Wm5OZL2UYKFe1KRJ86ePXiPZkkTYjZUWldAsaXk9ihowE2Lw==",
    type=>"ssh-rsa",
    user=>"hudson",
    target=>"/var/hudson/.ssh/authorized_keys",
    require=>File["/var/hudson/.ssh"]
 }
package{[ant,"openjdk-6-jdk"]:ensure=>present}
}
include hudson
