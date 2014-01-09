include_recipe 'jenkins::master'

# Execute some simple commands
jenkins_command 'clear-queue'
jenkins_command 'help'
jenkins_command 'version'

jenkins_command 'safe-shutdown'
