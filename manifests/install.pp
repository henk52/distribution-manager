
# Git server
#  Depends on Web server.

# Kickstart server
#  Depends on:
#   - web
#   - nfs
#   - the git tools.
#   - DHCP/TFTP servers, dnsmasq(bootserver)

$szWebServerPackage = 'apache'

#$szIpAddressForDHCPServer = '10.1.2.3'
#$szIpAddressSubnet = '10.1.2'
#$szWebProcessOwnerName = 'lighttpd'
$szWebProcessOwnerName = 'apache'

$szRepoWebHostAddr = hiera('IpAddressForSupportingKickStart')

$szKickStartBaseDirectory = hiera('KickStartBaseDirectory', '/var/ks')

$szGitTopDir = '/var/git'

# Directory where the hiera conf files are stored.
$szHieraConfigsDir = '/var/hieraconfs'

# TODO C define the GIT user.
# TODO C Create git dir.

$arAliases = [
  { 
    alias => '/git',
    path  => "$szGitTopDir",
  },
  {
    alias => '/hieraconfs',
    path  => "$szHieraConfigsDir",
  },
  {
    alias => '/images',
    path  => "$szKickStartBaseDirectory",
  }
]  

file { "$szHieraConfigsDir":
  ensure => directory,
}

file { "$szHieraConfigsDir/git_web_host_conf.yaml":
  ensure  => present,
  require => File [ "$szHieraConfigsDir" ],
  content => template('distribution-manager/git_web_host_conf_yaml.erb'),
}

$szDefaultNfsOptionList =  'ro,no_root_squash'
$szDefaultNfsClientList = hiera ( 'DefaultNfsClientList' )

$hNfsExports = {
 "$szKickStartBaseDirectory/configs" => {
             'NfsOptionList' => "$szDefaultNfsOptionList",
             'NfsClientList' => "$szDefaultNfsClientList",
                                        }, 
 "/home/ks" => {
             'NfsOptionList' => "$szDefaultNfsOptionList",
             'NfsClientList' => "$szDefaultNfsClientList",
                                        }, 
}
# "$szKickStartBaseDirectory/images" => {
# "$szKickStartBaseDirectory/images/fedora_20_x86_64" => {

# TODO C depend lighttpd on the GIT class
#class { 'lighttpd':
#  harAliasMappings => $arAliases,
#  szWebProcessOwnerName => $szWebProcessOwnerName,
#}


# Base class. Turn off the default vhosts; we will be declaring
# all vhosts below.
class { 'apache':
  default_vhost => false,
}



apache::vhost { 'subdomain.example.com':
  ip      => "$szRepoWebHostAddr",
  ip_based => true,
  port    => '80',
  docroot => '/var/www/subdomain',
  aliases => $arAliases,
}


class { 'nfsserver':
   hohNfsExports => $hNfsExports,
#  NfsExport => $arNfsExports,
}

# TODO V Add this to both class instantiation:  szWebProcessOwnerName =>  
class { 'gitserver':
  szWebServerPackage    => "$szWebServerPackage",
  szWebProcessOwnerName => "$szWebProcessOwnerName",
  szGitDirectory        => "$szGitTopDir",
  require               => Class ["$szWebServerPackage"],
}

class { 'bst':
  szWebProcessOwnerName    => "$szWebProcessOwnerName",
  szKickStartBaseDirectory => "$szKickStartBaseDirectory",
}

# TODO C open the Firewalld ports.
#firewalld::zone { 'public':
#  services => ['ssh', 'vnc-server'],
#}
##  services => ['ssh', 'dhcp', 'dns', 'http', 'nfs', 'rpc-bind', 'tftp', 'vnc-server'],
#
#firewalld::zone { 'internal':
#  interfaces => [ 'enp3s0' ],
#  services   => ['ssh', 'dhcp', 'dns', 'http', 'nfs', 'tftp', 'vnc-server'],
#  ports      => [{
#     comment         => 'sunrpc',
#     port            => '111',
#     protocol        => 'tcp',
#                },],
#}

service { 'firewalld':
  enable => false,
  ensure => stopped,
}


# TODO C Remove before launch. This is suppose to be part of the firewalld class.
# This is a workaround to the error of missing Package support.
#  See: https://github.com/jpopelka/puppet-firewalld/issues/1
package { 'firewalld':
  ensure => present,
}
#service { 'firewalld':
#                ensure     => running,  # ensure it's running
#                enable     => true,     # start on boot
#}

# TODO C Disable selinux.

class { 'bootserver':
#  szIpAddressForSupportingKickStart => $szIpAddressForDHCPServer,
#  szClassCSubnetAddress => $szIpAddressSubnet,
  szWebProcessOwnerName => $szWebProcessOwnerName,
  require        => Class ['apache'],
}
