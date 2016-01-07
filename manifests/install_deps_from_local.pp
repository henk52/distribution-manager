# apache
$szApacheDirName = 'puppetlabs-apache-1.5.0'
$szApacheTarName = "$szApacheDirName.tar.gz"
exec { 'get_apache_module':
  command => "wget http://dm/storage/puppet/$szApacheTarName",
  cwd     => '/etc/puppet/modules',
  creates => "/etc/puppet/modules/$szApacheTarName",
  path    => '/usr/bin',
}

exec { 'unpack_apache_module':
  command => "tar -zxf $szApacheTarName",
  cwd     => '/etc/puppet/modules',
  creates => "/etc/puppet/modules/$szApacheDirName",
  path    => '/usr/bin',
  require => Exec['get_apache_module'],
}

file { '/etc/puppet/modules/apache':
  ensure  => link,
  target  => "/etc/puppet/modules/$szApacheDirName",
  require => Exec['unpack_apache_module'],
}

$szConcatDirName = 'puppetlabs-concat-1.1.2'
$szConcatTarName = "$szConcatDirName.tar.gz"

exec { 'get_concat_module':
  command => "wget http://dm/storage/puppet/$szConcatTarName",
  cwd     => '/etc/puppet/modules',
  creates => "/etc/puppet/modules/$szConcatTarName",
  path    => '/usr/bin',
}

exec { 'unpack_concat_module':
  command => "tar -zxf $szConcatTarName",
  cwd     => '/etc/puppet/modules',
  creates => "/etc/puppet/modules/$szConcatDirName",
  path    => '/usr/bin',
  require => Exec['get_concat_module'],
}

file { '/etc/puppet/modules/concat':
  ensure  => link,
  target  => "/etc/puppet/modules/$szConcatDirName",
  require => Exec['unpack_concat_module'],
}

$szRsyncDirName = 'puppetlabs-rsync-0.4.0'
$szRsyncTarName = "$szRsyncDirName.tar.gz"

exec { 'get_rsync_module':
  command => "wget http://dm/storage/puppet/$szRsyncTarName",
  cwd     => '/etc/puppet/modules',
  creates => "/etc/puppet/modules/$szRsyncTarName",
  path    => '/usr/bin',
}

exec { 'unpack_rsync_module':
  command => "tar -zxf $szRsyncTarName",
  cwd     => '/etc/puppet/modules',
  creates => "/etc/puppet/modules/$szRsyncDirName",
  path    => '/usr/bin',
  require => Exec['get_rsync_module'],
}

file { '/etc/puppet/modules/rsync':
  ensure  => link,
  target  => "/etc/puppet/modules/$szRsyncDirName",
  require => Exec['unpack_rsync_module'],
}

# stdlib
# puppet module install razorsedge-network
$szNetworkDirName = 'razorsedge-network-3.6.0'
$szNetworkTarName = "$szNetworkDirName.tar.gz"

exec { 'get_network_module':
  command => "wget http://dm/storage/puppet/$szNetworkTarName",
  cwd     => '/etc/puppet/modules',
  creates => "/etc/puppet/modules/$szNetworkTarName",
  path    => '/usr/bin',
}

exec { 'unpack_network_module':
  command => "tar -zxf $szNetworkTarName",
  cwd     => '/etc/puppet/modules',
  creates => "/etc/puppet/modules/$szNetworkDirName",
  path    => '/usr/bin',
  require => Exec['get_network_module'],
}

file { '/etc/puppet/modules/network':
  ensure  => link,
  target  => "/etc/puppet/modules/$szNetworkDirName",
  require => Exec['unpack_network_module'],
}

# puppet module install puppetlabs-rsync
# git clone https://github.com/henk52/bootserver.git
exec { 'get_bootserver_module':
  command => 'git clone http://dm/git/bootserver.git',
  cwd     => '/etc/puppet/modules',
  creates => "/etc/puppet/modules/bootserver",
  path    => '/usr/bin',
}

# git clone https://github.com/henk52/henk52-nfsserver.git nfsserver
$szNfsServerModuleName = 'nfsserver'
exec { "get_${szNfsServerModuleName}_module":
  command => "git clone http://dm/git/henk52-$szNfsServerModuleName.git $szNfsServerModuleName",
  cwd     => '/etc/puppet/modules',
  creates => "/etc/puppet/modules/$szNfsServerModuleName",
  path    => '/usr/bin',
}

# git clone https://github.com/henk52/gitserver.git
$szGitServerModuleName = 'gitserver'
exec { "get_${szGitServerModuleName}_module":
  command => "git clone http://dm/git/$szGitServerModuleName.git $szGitServerModuleName",
  cwd     => '/etc/puppet/modules',
  creates => "/etc/puppet/modules/$szGitServerModuleName",
  path    => '/usr/bin',
}

# git clone https://github.com/henk52/henk52-bst.git bst
$szBstModuleName = 'bst'
exec { "get_${szBstModuleName}_module":
  command => "git clone http://dm/git/henk52-$szBstModuleName.git $szBstModuleName",
  cwd     => '/etc/puppet/modules',
  creates => "/etc/puppet/modules/$szBstModuleName",
  path    => '/usr/bin',
}


