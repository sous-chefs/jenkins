include_recipe 'jenkins_server_wrapper::default'
include_recipe 'jenkins_job::create'

#########################################################################
# execute simple job
#########################################################################

jenkins_job 'simple-execute' do
  action :build
end

#########################################################################
# execute job with params
#########################################################################

jenkins_job 'execute-with-params' do
  parameters(
    'STRING_PARAM' => 'meeseeks',
    'BOOLEAN_PARAM' => true
  )
  action :build
end
