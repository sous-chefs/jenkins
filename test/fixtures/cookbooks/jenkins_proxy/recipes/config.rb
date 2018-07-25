include_recipe 'jenkins_server_wrapper::default'

# Test incorrect proxy configuration
jenkins_proxy 'bad format'
jenkins_proxy 'bad:format'

# Test basic proxy configuration
jenkins_proxy '1.2.3.4:5678'

# Test same basic proxy configuration that have to skip
jenkins_proxy '1.2.3.4:5678'

# Test proxy configuration with attributes
jenkins_proxy '5.6.7.8:9012' do
  noproxy ['nohost', '*.nodomain']
end
