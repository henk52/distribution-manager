distribution-manager
====================

Distribution Manager: CLI administrated Kickstart server with GIT


Dependencies
============

# Instalation

1. cd /etc/puppet/modules
1. git clone https://github.com/henk52/distribution-manager.git
1. git clone https://github.com/jpopelka/puppet-firewalld.git firewalld
  * https://forge.puppetlabs.com/jpopelka/firewalld
  * https://jpopelka.fedorapeople.org/puppet-firewalld/doc/firewalld/service.html
1. git clone https://github.com/puppetlabs/puppetlabs-apache.git apache
1. git clone https://github.com/puppetlabs/puppetlabs-concat.git concat
1. git clone https://github.com/puppetlabs/puppetlabs-stdlib.git stdlib
1. git clone https://github.com/henk52/bootserver.git
1. git clone https://github.com/henk52/henk52-nfsserver.git nfsserver
1. git clone https://github.com/henk52/gitserver.git

Configuring the target node:
  wget http://10.1.2.3:/hieraconfs/git_web_host_conf.yaml -O /etc/puppet/data/defaults.yaml

# TROUBLESHOOTING

Add the missing "options => [ '+Indexes' ]" to the directory I was trying to CURL from.

 apache::vhost { 'subdomain.example.com':
+  directoryindex => 'disabled',
+  options        => [ '+Indexes' ],
+  directories => [
+    { path => "$szKickStartImageDirectory", options => [ '+Indexes' ], },
+  ],


[Mon Sep 08 19:19:32.694979 2014] [autoindex:error] [pid 12130] [client 10.1.233.113:40261] AH01276: Cannot serve directory /home/ks/repo/linux/releases/20/Everything/x86_64/os/Packages/f/: No matching DirectoryIndex (index.html,index.html.var,index.cgi,index.pl,index.php,index.xhtml) found, and server-generated directory index forbidden by Options directive

curl -L -f "http://10.1.233.3/images/linux/releases/20/Everything/x86_64/os/Packages/f"
curl: (22) The requested URL returned error: 403 Forbidden

http://stackoverflow.com/questions/21346486/how-to-show-directory-index-in-apache-2-4-with-custom-document-root
