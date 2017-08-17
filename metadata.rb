name             'airgapped_jenkins'
maintainer       'FoxGuard Solutions'
maintainer_email 'pumpdev@foxguardsolutions.com'
license          'Apache-2.0'
description      'Installs and configures an airgapped Jenkins CI master & slaves'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '5.1.0'

recipe 'airgapped_jenkins::master', 'Installs an airgapped Jenkins master'

%w(ubuntu debian redhat centos scientific oracle amazon).each do |os|
  supports os
end

depends 'compat_resource', '>= 12.16.3'
depends 'dpkg_autostart'

source_url 'https://github.com/chef-cookbooks/jenkins'
issues_url 'https://github.com/chef-cookbooks/jenkins/issues'
chef_version '>= 12.1' if respond_to?(:chef_version)
