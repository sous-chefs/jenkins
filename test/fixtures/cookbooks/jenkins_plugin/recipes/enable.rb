jenkins_plugin 'jira-trigger' do
  action :disable
end

# Test enable plugin
jenkins_plugin 'jira-trigger' do
  action :enable
end
