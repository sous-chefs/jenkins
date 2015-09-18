name             'jenkins'
maintainer       'Chef Software, Inc.'
maintainer_email 'releng@chef.io'
license          'Apache 2.0'
description      'Installs and configures Jenkins CI master & slaves'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '2.4.1'

source_url 'https://github.com/chef-cookbooks/jenkins' if respond_to?(:source_url)
issues_url 'https://github.com/chef-cookbooks/jenkins/issues' if respond_to?(:issues_url)

recipe 'jenkins::master', 'Installs a Jenkins master'

depends 'apt',   '~> 2.0'
depends 'runit', '~> 1.5'
depends 'yum',   '~> 3.0'
