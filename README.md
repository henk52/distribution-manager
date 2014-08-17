distribution-manager
====================

Distribution Manager: CLI administrated Kickstart server with GIT


Dependencies
============

1 cd /etc/puppet/modules
2 git clone https://github.com/jpopelka/puppet-firewalld.git firewalld
  * https://forge.puppetlabs.com/jpopelka/firewalld
  * https://jpopelka.fedorapeople.org/puppet-firewalld/doc/firewalld/service.html

Configuring the target node:
  wget http://10.1.2.3:/hieraconfs/git_web_host_conf.yaml -O /etc/puppet/data/defaults.yaml
