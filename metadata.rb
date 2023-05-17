name              'jenkins'
maintainer        'Sous Chefs'
maintainer_email  'help@sous-chefs.org'
license           'Apache-2.0'
description       'Installs and configures Jenkins CI master & slaves'
version           '9.5.14'
source_url        'https://github.com/sous-chefs/jenkins'
issues_url        'https://github.com/sous-chefs/jenkins/issues'
chef_version      '>= 16'

supports 'amazon'
supports 'centos'
supports 'debian'
supports 'oracle'
supports 'redhat'
supports 'scientific'
supports 'ubuntu'

depends 'dpkg_autostart'
depends 'yum-epel'
