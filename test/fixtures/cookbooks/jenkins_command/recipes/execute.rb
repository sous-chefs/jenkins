include_recipe 'jenkins::master'

# Execute a simple command
jenkins_command 'safe-shutdown'
