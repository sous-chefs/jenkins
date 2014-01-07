name             'jenkins'
maintainer       'Opscode, Inc.'
maintainer_email 'cookbooks@opscode.com'
license          'Apache 2.0'
description      'Installs and configures Jenkins CI server & slaves'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.2.3'

recipe 'server', 'Installs Jenkins server'

depends 'apt',   '~> 2.0'
depends 'java',  '~> 1.17'
depends 'runit', '~> 1.5'
depends 'yum',   '~> 3.0'
