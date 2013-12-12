include_recipe 'jenkins::server'

# Execute a simple command
jenkins_command 'safe-shutdown'
