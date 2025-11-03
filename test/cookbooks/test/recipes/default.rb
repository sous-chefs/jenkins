# Basic Jenkins installation test - no plugins, no auth
apt_update 'update' if platform_family?('debian')

openjdk_pkg_install '21'

node.default['jenkins']['java'] = '/usr/bin/java'

jenkins_install 'default'
