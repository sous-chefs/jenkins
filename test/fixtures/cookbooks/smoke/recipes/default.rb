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
include_recipe 'authentication::default'

#
# Commands
# ------------------------------
include_recipe 'jenkins_command::execute'

#
# Credentials
# ------------------------------
include_recipe 'jenkins_credentials::create'

#
# Jobs
# ------------------------------
include_recipe 'jenkins_job::create'

#
# Plugins
# ------------------------------
include_recipe 'jenkins_plugin::install'

#
# Script
# ------------------------------
include_recipe 'jenkins_script::execute'

#
# Slaves
# ------------------------------
# include_recipe 'jenkins_slave::create'

#
# Users
# ------------------------------
include_recipe 'jenkins_user::create'
