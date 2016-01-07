# == Class: distribution_manager
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
#  [*szNetworkInterfaceName*]
#    Optional.
#    Name of the NIC used for service hosting.
#    If not provided will try hiera('NetworkInterfaceName').
#    Defaults to second NIC.
#
#  [*szIpAddressForSupportingKickStart*]
#    Mandatory.
#    IP address the services.
#
#  [*szKickStartBaseDirectory*]
#    Optional.
#    Path that is the base for all the kickstart related files; Repos etc.
#    Defaults to /var/ks.
#
#  [*szKickStartImageDirectory*]
#    Optional.
#    Path to where the iso images are, unpacked.
#       images, are structures, extracted from DVDs/ISO images.
#    If not provided will try hiera('KickStartImageDirectory')
#    Defaults to: $szKickStartBaseDirectory/images
#
#  [*szKickStartMirrorBaseDirectory*]
#    Optional.
#    Path to where the release mirrors are, of e.g. Fedora 20.
#    If not provided will try hiera('KickStartMirrorBaseDirectory')
#    Defaults to: $szKickStartBaseDirectory/mirrors
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
# Add to hiera, e.g.: defaults.yaml
#IpAddressForSupportingKickStart: 192.168.40.3
#NetworkAddress: '192.168.40'
#DefaultNfsClientList: '192.168.40.0/255.255.255.0'

#
# class { distribution_manager: }

class distribution_manager (
  $szNetworkInterfaceName = hiera( 'NetworkInterfaceName', '' ),
  $szIpAddressForSupportingKickStart = hiera('IpAddressForSupportingKickStart'),
  $szKickStartBaseDirectory = hiera('KickStartBaseDirectory', '/var/ks'),
  $szKickStartImageDirectory = hiera('KickStartImageDirectory', "$szKickStartBaseDirectory/images"),
  $szKickStartMirrorBaseDirectory
                     = hiera('KickStartMirrorBaseDirectory', "${szKickStartBaseDirectory}/mirrors")
) {


# Git server
#  Depends on Web server.

# Kickstart server
#  Depends on:
#   - web
#   - nfs
#   - the git tools.
#   - DHCP/TFTP servers, dnsmasq(bootserver)

$szWebServerPackage = 'apache'

$szWebProcessOwnerName = 'apache'

$szRepoWebHostAddr = $szIpAddressForSupportingKickStart


$szKickStartExtraRepos = "$szKickStartBaseDirectory/extrarepos"

$szGitTopDir = '/var/git'

$szWebStorageDir = '/var/webstorage'

# Directory where the hiera conf files are stored.
$szHieraConfigsDir = '/var/hieraconfs'

$szServiceIpAddress = $szIpAddressForSupportingKickStart
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
    path  => "${szKickStartMirrorBaseDirectory}",
  },
  {
    alias => '/configs',
    path  => "${szKickStartBaseDirectory}/configs",
  },
  {
    alias => '/isoimages',
    path  => "${szKickStartBaseDirectory}/images",
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
  #content => template('distribution_manager/git_web_host_conf_yaml.erb'),

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
  szKickStartMirrorDirectory => "mirrors",
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
  szWebProcessOwnerName    => $szWebProcessOwnerName,
  szKickStartBaseDirectory => $szKickStartBaseDirectory,
  szKickStartImageDir      => $szKickStartImageDirectory,
  require                  => Class['apache'],
}

} # end class.
