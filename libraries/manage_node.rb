#
# Cookbook Name:: jenkins
# Library:: manage_node
#
# Author:: Doug MacEachern <dougm@vmware.com>
# Author:: Fletcher Nichol <fnichol@nichol.ca>
#
# Copyright 2010, VMware, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

def jenkins_node_defaults(args)
  args[:name] ||= nil # required
  args[:description] ||= ''
  args[:remote_fs] ||= nil # required
  args[:executors] ||= 1
  args[:mode] ||= 'NORMAL' # 'NORMAL' or 'EXCLUSIVE'
  args[:labels] ||= []
  args[:launcher] ||= 'jnlp' # 'jnlp' or 'command' or 'ssh'
  args[:availability] ||= 'Always' # 'Always' or 'Demand'
  args[:env] = args[:env] ? args[:env].to_hash : nil
  args[:mode].upcase!
  args[:availability].capitalize!

  if args[:availability] == 'Demand'
    args[:in_demand_delay] ||= 0
    args[:idle_delay] ||= 1
  end

  case args[:launcher]
  when 'jnlp'
  when 'command'
    args[:command] ||= ''
  when 'ssh'
    args[:host] ||= args[:name]
    args[:port] ||= 22
    args[:credentials_description] ||= args[:name]
    args[:username] ||= ''
    args[:private_key] ||= ''
    args[:jvm_options] ||= ''
    args[:host_dsa_public] ||= nil
    args[:host_rsa_public] ||= nil
  end

  args
end

# Check to see if the node needs any changes
#
# === Returns
# <true>:: If a change is required
# <false>:: If the nodes are identical
def jenkins_node_compare(current_node, new_node)
  new_node = jenkins_node_defaults(new_node)
  default = jenkins_node_defaults({})
  default.keys.each do |key|
    val = new_node[key] || default[key]
    if !val.nil? && current_node[key.to_s] != val
      Chef::Log.debug("#{new_node[:name]} node.#{key} changed (#{current_node[key.to_s]} != #{val})")
      return true
    end
  end
  Chef::Log.debug("#{new_node[:name]} node unchanged")
  false
end

# generate a groovy script to create/update nodes
def jenkins_node_manage(args) # rubocop:disable MethodLength
  args = jenkins_node_defaults(args)

  if args[:env]
    map = args[:env].map { |k, v| %Q("#{k}":"#{v}") }.join(',')
    env = "new hudson.EnvVars([#{map}])"
  else
    env = 'null'
  end

  case args[:launcher]
  when 'jnlp'
    launcher = 'new JNLPLauncher()'
  when 'command'
    launcher = %Q(new CommandLauncher("#{args[:command]}", env))
  when 'ssh'
    if args[:password].nil?
      password = 'null'
    else
      password = %Q("#{args[:password]}")
    end

    launcher = %Q(new_ssh_launcher("#{args[:host]}", #{args[:port]}, "#{args[:credentials_description]}",
                                    "#{args[:username]}", #{password},
                                    "#{args[:private_key]}", "#{args[:jvm_options]}"))
  end

  remote_fs = args[:remote_fs].gsub('\\', '\\\\\\') # C:\jenkins -> C:\\jenkins

  if args[:availability] == 'Demand'
    rs_args = "#{args[:in_demand_delay]}, #{args[:idle_delay]}"
  else
    rs_args = ''
  end

  <<EOF
import jenkins.model.*
import jenkins.slaves.*
import hudson.model.*
import hudson.slaves.*

app = Jenkins.instance
env = #{env}
props = []

def new_ssh_launcher(String host, int port, String credentialsDescription, String username, String password, String privateKey, String jvmOptions) {
  if (Jenkins.instance.pluginManager.getPlugin('ssh-credentials')) {
    def sshCredentials = com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials(com.cloudbees.jenkins.plugins.sshcredentials.SSHUser)
    def credentials = sshCredentials.find { it.username == username && it.description == credentialsDescription }
    if (credentials == null) {
      def privateKeySource = privateKey == '' || privateKey == null ? new com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey.UsersPrivateKeySource() : new com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey.DirectEntryPrivateKeySource(privateKey)
      def passphrase = ''
      credentials = new com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey(
        com.cloudbees.plugins.credentials.CredentialsScope.GLOBAL, null,
        username, privateKeySource, passphrase, credentialsDescription)

      def store = com.cloudbees.plugins.credentials.CredentialsProvider.lookupStores(Jenkins.instance).iterator().next()
      store.addCredentials(com.cloudbees.plugins.credentials.domains.Domain.global(), credentials)
    }

    new hudson.plugins.sshslaves.SSHLauncher(host, port, credentials, jvmOptions, null, null, null)
  } else {
    new hudson.plugins.sshslaves.SSHLauncher(host, port, username, password, privateKey, jvmOptions)
  }
}

if (env != null) {
  entries = env.map { k,v -> new EnvironmentVariablesNodeProperty.Entry(k,v) }
  props << new EnvironmentVariablesNodeProperty(entries)
}

slave = new DumbSlave("#{args[:name]}", "#{args[:description]}", "#{remote_fs}",
                      "#{args[:executors]}", Node.Mode.#{args[:mode]}, "#{args[:labels].join(" ")}",
                       #{launcher},
                       new RetentionStrategy.#{args[:availability]}(#{rs_args}), props)

nodes = new ArrayList(app.getNodes())
ix = nodes.indexOf(slave)
if (ix >= 0) {
  nodes.set(ix, slave)
}
else {
  nodes.add(slave)
}

app.setNodes(nodes)

EOF
end

# ruby manage_node.rb name slave-hostname remote_fs /home/jenkins ... | java -jar jenkins-cli.jar -s http://jenkins:8080/ groovy =
if File.basename($PROGRAM_NAME) == File.basename(__FILE__)
  args = {}
  ARGV.each_slice(2) do |k, v|
    args[k.to_sym] = v
  end
  puts jenkins_node_manage(args)
end
