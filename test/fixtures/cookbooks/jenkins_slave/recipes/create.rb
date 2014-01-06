include_recipe 'jenkins::server'

##################################################
# JNLP Slaves
##################################################

# Test basic JNLP slave creation
jenkins_jnlp_slave 'grimlock' do
  description 'full of cesium salami'
  remote_fs '/tmp/jenkins/slaves/grimlock'
  service_name 'jenkins-slave-grimlock'
  labels %w{ transformer autobot dinobot }
  user 'jenkins-grimlock'
  group 'jenkins-grimlock'
end

# Test with environment variables
jenkins_jnlp_slave 'shrapnel' do
  description 'bugs are cool'
  remote_fs '/tmp/jenkins/slaves/shrapnel'
  service_name 'jenkins-slave-shrapnel'
  labels %w{ transformer decepticon insecticon }
  environment(
    'FOO' => 'bar',
    'BAZ' => 'qux'
  )
  user 'jenkins-shrapnel'
  group 'jenkins-shrapnel'
end

# Test more exotic JNLP slave creation
jenkins_jnlp_slave 'soundwave' do
  description 'casettes are still cool'
  remote_fs '/tmp/jenkins/slaves/soundwave'
  service_name 'jenkins-slave-soundwave'
  executors 5
  usage_mode 'exclusive'
  availability 'demand'
  in_demand_delay 1
  idle_delay 3
  labels %w{ transformer decepticon badass }
  user 'jenkins-soundwave'
  group 'jenkins-soundwave'
end

##################################################
# SSH Slaves
##################################################

# Ugh...need to find a better way to do this...
jenkins_master_pk = File.read(File.expand_path('../../../../../data/data/test_id_rsa', __FILE__))

# Test SSH slave creation - credentials from resource
c = jenkins_private_key_credentials 'jenkins-starscream' do
  private_key jenkins_master_pk
end

jenkins_ssh_slave 'starscream' do
  description 'should be the leader'
  remote_fs '/tmp/jenkins/slaves/starscream'
  labels %w{ transformer decepticon seeker }
  user 'jenkins-starscream'
  group 'jenkins-starscream'
  # SSH specific attributes
  host 'localhost'
  credentials c
end

# Test SSH slave creation - credentials from ID
jenkins_private_key_credentials 'jenkins-skywarp' do
  id '38537014-ec66-49b5-aff2-aed1c19e2989'
  private_key jenkins_master_pk
end

jenkins_ssh_slave 'skywarp' do
  remote_fs '/tmp/jenkins/slaves/skywarp'
  labels %w{ transformer decepticon seeker }
  user 'jenkins-skywarp'
  group 'jenkins-skywarp'
  # SSH specific attributes
  host 'localhost'
  credentials '38537014-ec66-49b5-aff2-aed1c19e2989'
end

# Test SSH slave creation - credentials from username
jenkins_private_key_credentials 'jenkins-thundercracker' do
  private_key jenkins_master_pk
end

jenkins_ssh_slave 'thundercracker' do
  remote_fs '/tmp/jenkins/slaves/thundercracker'
  labels %w{ transformer decepticon seeker }
  user 'jenkins-thundercracker'
  group 'jenkins-thundercracker'
  # SSH specific attributes
  host 'localhost'
  credentials 'jenkins-thundercracker'
end
