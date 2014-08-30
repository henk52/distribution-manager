service { 'lighttpd':
  ensure => stopped,
  enable => false,
}

package { 'lighttpd':
  ensure => absent,
  require => Service [ 'lighttpd' ],
}
