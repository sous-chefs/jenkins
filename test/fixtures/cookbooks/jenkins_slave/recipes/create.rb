include_recipe 'jenkins::server'

# Test basic JNLP slave creation
jenkins_jnlp_slave 'grimlock' do
  description 'full of cesium salami'
  remote_fs '/tmp/jenkins/slaves/grimlock'
  labels %w{ transformer autobot dinobot }
end

# Ugh...need to find a better way to do this...
jenkins_master_pk = ''
ruby_block 'read SSH private key' do
  block do
    jenkins_master_pk.replace(IO.read(File.join(node['jenkins']['server']['home'], '.ssh', 'id_rsa')))
  end
end

# Create a set of credentials on the master
c = jenkins_private_key_credentials node['jenkins']['server']['user'] do
      id '38537014-ec66-49b5-aff2-aed1c19e2989'
      private_key jenkins_master_pk
    end

# Test SSH slave creation - credentials from resource
jenkins_ssh_slave 'starscream' do
  description 'should be the leader'
  remote_fs '/tmp/jenkins/slaves/starscream'
  labels %w{ transformer decepticon seeker }
  # SSH specific attributes
  host 'localhost'
  credentials c
end

# Test SSH slave creation - credentials from ID
jenkins_ssh_slave 'skywarp' do
  remote_fs '/tmp/jenkins/slaves/skywarp'
  labels %w{ transformer decepticon seeker }
  # SSH specific attributes
  host 'localhost'
  credentials '38537014-ec66-49b5-aff2-aed1c19e2989'
end

# Test SSH slave creation - credentials from username
jenkins_ssh_slave 'thundercracker' do
  remote_fs '/tmp/jenkins/slaves/thundercracker'
  labels %w{ transformer decepticon seeker }
  # SSH specific attributes
  host 'localhost'
  credentials node['jenkins']['server']['user']
end

# Test more exotic JNLP slave creation
jenkins_jnlp_slave 'soundwave' do
  description 'casettes are still cool'
  remote_fs '/tmp/jenkins/slaves/soundwave'
  executors 5
  usage_mode 'exclusive'
  availability 'demand'
  in_demand_delay 1
  idle_delay 3
  labels %w{ transformer decepticon badass }
end

# Test with environment variables
jenkins_jnlp_slave 'shrapnel' do
  description 'bugs are cool'
  remote_fs '/tmp/jenkins/slaves/shrapnel'
  labels %w{ transformer decepticon insecticon }
  environment(
    FOO: 'bar',
    BAZ: 'qux'
  )
end
