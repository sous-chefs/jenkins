name             "jenkins"
maintainer       "AJ Christensen"
maintainer_email "aj@junglist.gen.nz"
license          "Apache 2.0"
description      "Installs and configures Jenkins CI server & slaves"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.6.3"

depends "java"
depends "runit"

recommends "apt"

suggests "apache2"
suggests "nginx"
suggests "iptables"
