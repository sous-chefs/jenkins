include_recipe 'jenkins::server'

#
# Execute a command
#
jenkins_command 'quiet-down'
