name             "jenkins"
maintainer       "Opscode, Inc."
maintainer_email "cookbooks@opscode.com"
license          "Apache 2.0"
description      "Installs and configures Jenkins CI server & slaves"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.8.0"

depends "java"
depends "runit", ">= 1.0.0"

suggests "apache2"
suggests "nginx"
suggests "iptables"
