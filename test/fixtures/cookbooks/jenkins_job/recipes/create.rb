include_recipe 'jenkins_server_wrapper::default'

%w(
  simple-execute
  execute-with-params
).each do |job_name|
  config = File.join(Chef::Config[:file_cache_path], "#{job_name}.xml")
  cookbook_file config

  # Test basic job creation
  jenkins_job job_name do
    config config
    action :create
  end
end
