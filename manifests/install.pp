
# Git server
#  Depends on Web server.

# Kickstart server
#  Depends on:
#   - web
#   - nfs
#   - the git tools.
#   - DHCP/TFTP servers, dnsmasq(bootserver)


#$szIpAddressForDHCPServer = '10.1.2.3'
#$szIpAddressSubnet = '10.1.2'
#$szWebProcessOwnerName = 'lighttpd'

$szGitTopDir = '/var/git'
# TODO C define the GIT user.
# TODO C Create git dir.

$arAliases = {
  '/git' => "$szGitTopDir",
}  

# TODO C depend lighttpd on the GIT class
class { 'lighttpd':
  harAliasMappings => $arAliases,
  szWebProcessOwnerName => $szWebProcessOwnerName,
}

# TODO V Add this to both class instantiation:  szWebProcessOwnerName =>  
class { 'gitserver':
  szGitDirectory => $szGitTopDir,
  require        => Class ['lighttpd'],
}

# TODO C open the Firewalld ports.
firewalld::zone { 'public':
  services => ['ssh', 'dhcp', 'dns', 'http', 'tftp', 'vnc-server'],
}


# TODO C Remove before launch. This is suppose to be part of the firewalld class.
# This is a workaround to the error of missing Package support.
#  See: https://github.com/jpopelka/puppet-firewalld/issues/1
package { 'firewalld':
  ensure => present,
}
service { 'firewalld':
                ensure     => running,  # ensure it's running
                enable     => true,     # start on boot
}

# TODO C Disable selinux.

class { 'bootserver':
#  szIpAddressForSupportingKickStart => $szIpAddressForDHCPServer,
#  szClassCSubnetAddress => $szIpAddressSubnet,
  szWebProcessOwnerName => $szWebProcessOwnerName,
}
