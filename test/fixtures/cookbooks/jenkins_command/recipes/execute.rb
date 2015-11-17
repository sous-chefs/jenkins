include_recipe 'jenkins_server_wrapper::default'

# Execute some simple commands
jenkins_command 'clear-queue'
jenkins_command 'help'
jenkins_command 'version'
