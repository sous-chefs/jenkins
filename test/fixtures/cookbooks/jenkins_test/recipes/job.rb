include_recipe 'jenkins::server'

config = File.join('/tmp/config.xml')
template(config) { source 'config.xml.erb' }
jenkins_job('bacon') { config config }

jenkins_job('bacon') { action :disable }
jenkins_job('bacon') { action :disable }
jenkins_job('bacon') { action :enable }
jenkins_job('bacon') { action :enable }
jenkins_job('bacon') { action :delete }
jenkins_job('bacon') { action :delete }
