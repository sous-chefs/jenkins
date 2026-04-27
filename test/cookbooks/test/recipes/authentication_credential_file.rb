include_recipe 'test::default'

file '/var/lib/jenkins/.cli-credentials' do
  content 'chef:chefadmin123'
  owner 'jenkins'
  group 'jenkins'
  mode '0600'
  sensitive true
end

jenkins_executor_config 'credential file auth' do
  timeout 300
  cli_credential_file '/var/lib/jenkins/.cli-credentials'
end

file "#{Chef::Config[:file_cache_path]}/secure-smoke-job.xml" do
  content <<~XML
    <?xml version='1.1' encoding='UTF-8'?>
    <project>
      <actions/>
      <description>Secure smoke job</description>
      <keepDependencies>false</keepDependencies>
      <properties/>
      <scm class="hudson.scm.NullSCM"/>
      <canRoam>true</canRoam>
      <disabled>false</disabled>
      <blockBuildWhenDownstreamBuilding>false</blockBuildWhenDownstreamBuilding>
      <blockBuildWhenUpstreamBuilding>false</blockBuildWhenUpstreamBuilding>
      <triggers/>
      <concurrentBuild>false</concurrentBuild>
      <builders>
        <hudson.tasks.Shell>
          <command>echo secure credential file</command>
        </hudson.tasks.Shell>
      </builders>
      <publishers/>
      <buildWrappers/>
    </project>
  XML
  mode '0644'
end

jenkins_script 'write credential file marker' do
  command <<~GROOVY
    import jenkins.model.Jenkins

    def marker = new File(Jenkins.getInstance().getRootDir(), 'chef-script-marker.txt')
    marker.text = 'credential-file'
  GROOVY
  action :execute
end

jenkins_user 'random-bob' do
  full_name 'Random Bob'
  password 'randompassword123'
end

jenkins_job 'secure-smoke' do
  config "#{Chef::Config[:file_cache_path]}/secure-smoke-job.xml"
end

jenkins_plugin 'greenballs'

execute 'restart jenkins after credential file plugin install' do
  command 'systemctl restart jenkins'
  action :run
end

ruby_block 'wait for jenkins after credential file plugin install' do
  block do
    require 'net/http'
    require 'uri'

    ready = false

    120.times do
      begin
        response = Net::HTTP.get_response(URI.parse('http://127.0.0.1:8080/login'))
        if %w(200 403).include?(response.code)
          ready = true
          break
        end
      rescue StandardError => e
        Chef::Log.debug("Waiting for Jenkins plugin restart: #{e.message}")
      end

      sleep 2
    end

    raise 'Jenkins did not become reachable after credential-file plugin restart' unless ready
  end
end
