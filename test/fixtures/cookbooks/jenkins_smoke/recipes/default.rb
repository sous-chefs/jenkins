include_recipe 'jenkins_server_wrapper::default'

#
# This recipe is a meta-collection of some common paths in the Jenkins cookbook.
# It should be run instead of the individual resource tests during trivial
# patches.
#
# This recipe will:
#
#   - Execute some basic commands
#   - Manage credentials (create)
#   - Manage jobs (create)
#   - Manage plugins (install)
#   - Execute some Groovy scripts
#   - Manage JNLP slaves (create)
#   - Manage SSH slaves (create)
#

#
# Authentication
# ------------------------------
include_recipe 'jenkins_authentication::private_key'

#
# Commands
# ------------------------------
include_recipe 'jenkins_command::execute'

#
# Credentials
# ------------------------------
include_recipe 'jenkins_credentials::default'

#
# Jobs
# ------------------------------
include_recipe 'jenkins_job::default'

#
# Plugins
# ------------------------------
include_recipe 'jenkins_plugin::default'

#
# Proxy
# ------------------------------
include_recipe 'jenkins_proxy::config'

#
# Script
# ------------------------------
include_recipe 'jenkins_script::execute'

#
# Slaves
# ------------------------------
include_recipe 'jenkins_slave::default'

#
# Users
# ------------------------------
include_recipe 'jenkins_user::default'

