name             'jenkins'
maintainer       'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license          'Apache-2.0'
description      'Installs and configures Jenkins CI master & slaves'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '5.0.1'

recipe 'jenkins::master', 'Installs a Jenkins master'

%w(ubuntu debian redhat centos scientific oracle amazon).each do |os|
  supports os
end

depends 'runit', '>= 1.7'
depends 'compat_resource', '>= 12.16.3'
depends 'dpkg_autostart'

source_url 'https://github.com/chef-cookbooks/jenkins'
issues_url 'https://github.com/chef-cookbooks/jenkins/issues'
chef_version '>= 12.1' if respond_to?(:chef_version)
