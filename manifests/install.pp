
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
# images, are structures, extracted from DVDs/ISO images.
$szKickStartImageDirectory
  = hiera('KickStartImageDirectory', "${szKickStartBaseDirectory}/images")
$szKickStartMirrorBaseDirectory
  = hiera('KickStartMirrorBaseDirectory', "${szKickStartBaseDirectory}/mirrors")

$szKickStartExtraRepos = '/var/ks/extrarepos'

$szGitTopDir = '/var/git'

$szWebStorageDir = '/var/webstorage'

# Directory where the hiera conf files are stored.
$szHieraConfigsDir = '/var/hieraconfs'

$szNetworkInterfaceName = hiera( 'NetworkInterfaceName', '' ) 
$szServiceIpAddress = hiera( 'IpAddressForSupportingKickStart', '172.16.1.3' )
  #if $szNetworkInterfaceName not set then set it 
if ( $szNetworkInterfaceName == '' ) { 
  # # Facter: interfaces (Array of interfaces), grab the second entry.
  notify{ "Network interface name not set.": } 
  $arInterfaceList = split($interfaces, ',')
  $szNicName = $arInterfaceList[1] 
} else { 
  $szNicName = $szNetworkInterfaceName 
}
notify{ "NIC: $szNicName ( $szServiceIpAddress )": }

network::if::static { "${szNicName}":
  ensure    => 'up',
  ipaddress => "${szServiceIpAddress}",
  netmask   => '255.255.255.0',
}

# Set SE Linux to allow everything, but keep tracking.
file_line { 'set_selinux_permisive':
  path => '/etc/selinux/config',
  line => 'SELINUX=permissive',
  match => '^SELINUX=enforcing'
}

exec { 'temporarily_set_selinux_permisive':
  command => 'setenforce 0',
  onlyif  => 'sestatus | grep mode  | grep -q enforcing',
  path    => ['/usr/sbin','/usr/bin'],
}

# TODO C define the GIT user.

file { "${szWebStorageDir}":
  ensure => directory,
}

$arAliases = [
  {
    alias => '/git',
    path  => "${szGitTopDir}",
  },
  {
    alias => '/storage',
    path  => "${szWebStorageDir}",
  },
  {
    alias => '/hieraconfs',
    path  => "${szHieraConfigsDir}",
  },
  {
    alias => '/images',
    path  => "${szKickStartImageDirectory}",
  },
  {
    alias => '/mirrors',
    path  => "$szKickStartMirrorBaseDirectory",
  },
  {
    alias => '/configs',
    path  => '/var/ks/configs',
  },
  {
    alias => '/isoimages',
    path  => '/var/ks/images',
  },
  {
    alias => '/extrarepos',
    path  => "${szKickStartExtraRepos}",
  },
  {
    alias => '/rhel/4.4',
    path  => "${szKickStartExtraRepos}/cloudstack_4.4",
  },
  {
    alias => '/systemvm/4.4',
    path  => "${szKickStartExtraRepos}/cloudstack_4.4",
  },

]


# TODO Should this also be moved to the boot server module?
file { "${szHieraConfigsDir}":
  ensure  => directory,
  require => File["${szKickStartBaseDirectory}"],
}


file { "${szHieraConfigsDir}/git_web_host_conf.yaml":
  ensure  => present,
  require => File["${szHieraConfigsDir}"],
  content => inline_template("---\nRepoWebHostAddress: '<%= @szRepoWebHostAddr %>'"),
}
  #content => template('distribution-manager/git_web_host_conf_yaml.erb'),

$szDefaultNfsOptionList =  'ro,no_root_squash'
$szDefaultNfsClientList = hiera ( 'DefaultNfsClientList' )

$hNfsExports = {
  "${szKickStartBaseDirectory}/configs" => {
    'NfsOptionList' => "${szDefaultNfsOptionList}",
    'NfsClientList' => "${szDefaultNfsClientList}",
                                        },
  "${szKickStartBaseDirectory}" => {
    'NfsOptionList' => "${szDefaultNfsOptionList}",
    'NfsClientList' => "${szDefaultNfsClientList}",
                                        },
  "${szKickStartImageDirectory}" => {
    'NfsOptionList' => "${szDefaultNfsOptionList}",
    'NfsClientList' => "${szDefaultNfsClientList}",
                                        },
  "${szKickStartMirrorBaseDirectory}" => {
    'NfsOptionList' => "${szDefaultNfsOptionList}",
    'NfsClientList' => "${szDefaultNfsClientList}",
                                        },
}


# rsync is needed by LXC for getting some of the files.
include rsync::server

# The 'linux' added to the end, is for the mirror of the Fedora repos
# TODO V make the '/linux' configurable.
rsync::server::module{ 'fedora':
  path    => "${szKickStartImageDirectory}/linux",
}

# RSYNC server
# TODO fix it so that this is what is actualy read from hiera.
rsync::server::module{ 'images':
  path      => "${szKickStartBaseDirectory}/images",
  read_only => 'yes',
  list      => 'yes',
}
# TODO why does it work for extrareois and not this?
#  require   => File[ "${szKickStartBaseDirectory}/images" ],

rsync::server::module{ 'extrarepos':
  path      => "${szKickStartExtraRepos}",
  require   => File[ "${szKickStartExtraRepos}" ],
  read_only => 'yes',
  list      => 'yes',
}

rsync::server::module{ 'webstorage':
  path      => "${szWebStorageDir}",
  require   => File[ "${szWebStorageDir}" ],
  read_only => 'yes',
  list      => 'yes',
}


# TODO C depend lighttpd on the GIT class
#class { 'lighttpd':
#  harAliasMappings => $arAliases,
#  {szWebProcessOwnerName} => ${szWebProcessOwnerName},
#}


# Base class. Turn off the default vhosts; we will be declaring
# all vhosts below.
class { 'apache':
  default_vhost => false,
  require       => Exec['temporarily_set_selinux_permisive'],
}



# TODO C Move the 'directories' directive from a harcode,
#  to a configurable thing.
apache::vhost { 'subdomain.example.com':
  ensure         => present,
  ip             => "${szRepoWebHostAddr}",
  ip_based       => true,
  port           => '80',
  docroot        => '/var/www/subdomain',
  aliases        => $arAliases,
  directoryindex => 'disabled',
  options        => [ '+Indexes' ],
  directories => [
    { path => "$szKickStartImageDirectory", options => [ '+Indexes' ], },
    { path => "$szKickStartMirrorBaseDirectory", options => [ '+Indexes' ], },
  ],
}


class { 'nfsserver':
  hohNfsExports => $hNfsExports,
#  NfsExport => $arNfsExports,
  require       => Exec['temporarily_set_selinux_permisive'],
}

# TODO V Add this to both class instantiation:  {szWebProcessOwnerName} =>  
class { 'gitserver':
  szWebServerPackage    => "${szWebServerPackage}",
  szWebProcessOwnerName => "${szWebProcessOwnerName}",
  szGitDirectory        => "${szGitTopDir}",
  require               => Class['apache'],
  #require               => Class ["${szWebServerPackage}"],
}

# TODO N find out if this is really dependens on selinux permisive.
class { 'bst':
  szWebProcessOwnerName     => "${szWebProcessOwnerName}",
  szKickStartBaseDirectory  => "${szKickStartBaseDirectory}",
  szKickStartImageDirectory => "${szKickStartImageDirectory}",
  szKickStartMirrorDirectory => "${szKickStartMirrorBaseDirectory}",
  require                   => Exec['temporarily_set_selinux_permisive'],
}

# TODO C open the Firewalld ports.
#firewalld::zone { 'public':
#  services => ['ssh', 'vnc-server'],
#}
##  services => ['ssh', 'dhcp', 'dns', 'http', 'nfs',
##               'rpc-bind', 'tftp', 'vnc-server'],
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
  ensure => stopped,
  enable => false,
}


# TODO C Remove before launch. This is suppose to be part of the firewalld class
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
#  szClassCSubnetAddress   => $szIpAddressSubnet,
  szWebProcessOwnerName    => $szWebProcessOwnerName,
  szKickStartBaseDirectory => $szKickStartBaseDirectory,
  szKickStartImageDir      => $szKickStartImageDirectory,
  require                  => Class['apache'],
}

