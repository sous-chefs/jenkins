require 'berkshelf/vagrant'

Vagrant::Config.run do |config|
  # The path to the Berksfile to use with Vagrant Berkshelf
  config.berkshelf.berksfile_path = "./Berksfile"

  # An array of symbols representing groups of cookbook described in the Vagrantfile
  # to skip installing and copying to Vagrant's shelf.
  # config.berkshelf.only = []

  # An array of symbols representing groups of cookbook described in the Vagrantfile
  # to skip installing and copying to Vagrant's shelf.
  # config.berkshelf.except = []

  config.vm.define :master do |master_config|
    master_config.vm.host_name = "jenkins-master"
    master_config.vm.box = "opscode-ubuntu-12.04"
    master_config.vm.box_url = "https://opscode-vm.s3.amazonaws.com/vagrant/boxes/opscode-ubuntu-12.04.box"

    master_config.vm.network :hostonly, "33.33.33.10"
    master_config.ssh.max_tries = 40
    master_config.ssh.timeout   = 120
    master_config.ssh.forward_agent = true

    master_config.vm.provision :chef_solo do |chef|
      chef.json = {
        :jenkins => {

        }
      }

      chef.run_list = [
        "recipe[apt]",
        "recipe[jenkins::server]"
      ]
    end
  end

  config.vm.define :slave_ubuntu_10_04 do |slave_config|
    slave_config.vm.host_name = "jenkins-slave-ubuntu-10.04"
    slave_config.vm.box = "opscode-ubuntu-10.04"
    slave_config.vm.box_url = "https://opscode-vm.s3.amazonaws.com/vagrant/boxes/opscode-ubuntu-10.04.box"

    slave_config.vm.network :hostonly, "33.33.33.11"
    slave_config.ssh.max_tries = 40
    slave_config.ssh.timeout   = 120
    slave_config.ssh.forward_agent = true

    slave_config.vm.provision :chef_solo do |chef|
      chef.json = {
        :jenkins => {
          :server => {
            :port => 8080,
            :host => "33.33.33.10",
            :url => "http://33.33.33.10:8080"
          },
          :node => {
            :labels => %w{
              ubuntu-10-04
              x64
              chef-server-builder
            }
          }
        }
      }

      chef.run_list = [
        "recipe[apt]",
        "recipe[jenkins::node_jnlp]"
      ]
    end
  end
end
