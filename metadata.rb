name             'jenkins'
maintainer       'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license          'Apache-2.0'
description      'Installs and configures Jenkins CI master & slaves'

version          '8.0.2'

%w(ubuntu debian redhat centos scientific oracle amazon).each do |os|
  supports os
end

depends 'runit', '>= 1.7'
depends 'dpkg_autostart'

source_url 'https://github.com/chef-cookbooks/jenkins'
issues_url 'https://github.com/chef-cookbooks/jenkins/issues'

chef_version '>= 13.0'
