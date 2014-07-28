
# Git server
#  Depends on Web server.

# Kickstart server
#  Depends on:
#   - web
#   - nfs
#   - the git tools.

$arAliases = {
  'git' => '/var/git',
  'test' => '/var/test',
}  

class { "lighttpd":
  harAliasMappings => $arAliases,
}

# TODO C open the Firewalld ports.

# TODO C Disable selinux.
