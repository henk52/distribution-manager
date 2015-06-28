# == Class: distribution-manager
#
# Full description of class manager here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
# class { distribution-manager: }

class distribution-manager (
  $szNetworkInterfaceName = hiera( 'NetworkInterfaceName', '' ),
  $szRepoWebHostAddr = hiera('IpAddressForSupportingKickStart'),
  $szKickStartBaseDirectory = hiera('KickStartBaseDirectory', '/var/ks'),
  $szKickStartImageDirectory = hiera('KickStartImageDirectory', "$szKickStartBaseDirectory/images")
) {

$szWebServerPackage = 'apache'

$szWebProcessOwnerName = 'apache'


$szKickStartExtraRepos = '/var/ks/extrarepos'

$szGitTopDir = '/var/git'

$szWebStorageDir = '/var/webstorage'

# Directory where the hiera conf files are stored.
$szHieraConfigsDir = '/var/hieraconfs'

file { "$szWebStorageDir":
  ensure => directory,
}

$arAliases = [
  { 
    alias => '/git',
    path  => "$szGitTopDir",
  },
  { 
    alias => '/storage',
    path  => "$szWebStorageDir",
  },
  {
    alias => '/hieraconfs',
    path  => "$szHieraConfigsDir",
  },
  {
    alias => '/images',
    path  => "$szKickStartImageDirectory",
  },
  {
    alias => '/configs',
    path  => "/var/ks/configs",
  },
  {
    alias => '/isoimages',
    path  => "/var/ks/images",
  },
  {
    alias => '/extrarepos',
    path  => "$szKickStartExtraRepos",
  },
  {
    alias => '/rhel/4.4',
    path  => "$szKickStartExtraRepos/cloudstack_4.4",
  },
  {
    alias => '/systemvm/4.4',
    path  => "$szKickStartExtraRepos/cloudstack_4.4",
  },

]  


# TODO Should this also be moved to the boot server module?
file { "$szHieraConfigsDir":
  ensure => directory,
  require => File [ "$szKickStartBaseDirectory" ],
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
 "$szKickStartBaseDirectory" => {
             'NfsOptionList' => "$szDefaultNfsOptionList",
             'NfsClientList' => "$szDefaultNfsClientList",
                                        }, 
 "$szKickStartImageDirectory" => {
             'NfsOptionList' => "$szDefaultNfsOptionList",
             'NfsClientList' => "$szDefaultNfsClientList",
                                        }, 
}


# rsync is needed by LXC for getting some of the files.
include rsync::server

# The 'linux' added to the end, is for the mirror of the Fedora repos
# TODO V make the '/linux' configurable.
rsync::server::module{ 'fedora':
  path    => "$szKickStartImageDirectory/linux",
}

# RSYNC server
# TODO fix it so that this is what is actualy read from hiera.
rsync::server::module{ 'images':
  path      => "$szKickStartBaseDirectory/images",
  read_only => 'yes',
  list      => 'yes',
}
# TODO why does it work for extrareois and not this?  require   => File[ "$szKickStartBaseDirectory/images" ],

rsync::server::module{ 'extrarepos':
  path      => "$szKickStartExtraRepos",
  require   => File[ "$szKickStartExtraRepos" ],
  read_only => 'yes',
  list      => 'yes',
}

rsync::server::module{ 'webstorage':
  path      => "$szWebStorageDir",
  require   => File[ "$szWebStorageDir" ],
  read_only => 'yes',
  list      => 'yes',
}


# Base class. Turn off the default vhosts; we will be declaring
# all vhosts below.
class { 'apache':
  default_vhost => false,
}



# TODO C Move the 'directories' directive from a harcode, to a configurable thing.
apache::vhost { 'subdomain.example.com':
  ensure         => present,
  ip             => "$szRepoWebHostAddr",
  ip_based       => true,
  port           => '80',
  docroot        => '/var/www/subdomain',
  aliases        => $arAliases,
  directoryindex => 'disabled',
  options        => [ '+Indexes' ],
  directories => [
    { path => "$szKickStartImageDirectory", options => [ '+Indexes' ], },
  ],
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
  szWebProcessOwnerName     => "$szWebProcessOwnerName",
  szKickStartBaseDirectory  => "$szKickStartBaseDirectory",
  szKickStartImageDirectory => "$szKickStartImageDirectory",
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
#  szClassCSubnetAddress   => $szIpAddressSubnet,
  szWebProcessOwnerName    => $szWebProcessOwnerName,
  szKickStartBaseDirectory => $szKickStartBaseDirectory,
  szKickStartImageDir      => $szKickStartImageDirectory,
  require        => Class ['apache'],
}

}
