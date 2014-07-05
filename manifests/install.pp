
# Git server
#  Depends on Web server.

# Kickstart server
#  Depends on:
#   - web
#   - nfs
#   - the git tools.

$arAliases = [
  { alias => 'git', destination => '/var/git' } 
             ]

class { "lighttpd":
}

# TODO C open the Firewalld ports.

# TODO C Disable selinux.
