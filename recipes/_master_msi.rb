#
# Cookbook Name:: jenkins
# Recipe:: _master_msi
#
# Author: Troy Ready <troy@troyready.com>
#
# Copyright:: 2017, Sturdy Networks
# Copyright:: 2014-2017, Chef Software, Inc.
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

if ::File.extname(node['jenkins']['master']['source']) == '.zip'
  include_recipe 'ark::default'

  cached_jenkins_msi = ::File.join(Chef::Config[:file_cache_path],
                                   "jenkins-#{node['jenkins']['master']['version']}.msi")
  jenkins_msi_source = cached_jenkins_msi

  unless ::File.exist? cached_jenkins_msi
    ark "jenkins-#{node['jenkins']['master']['version']}" do
      url node['jenkins']['master']['source']
      checksum node['jenkins']['master']['checksum'] if node['jenkins']['master']['checksum']
      creates 'jenkins.msi'
      path Chef::Config[:file_cache_path]
      action :cherry_pick
    end
    ruby_block 'rename_generic_jenkins_msi_file' do
      block do
        require 'fileutils'
        ::FileUtils.mv(::File.join(Chef::Config[:file_cache_path], 'jenkins.msi'), cached_jenkins_msi)
      end
    end
  end
else
  jenkins_msi_source = node['jenkins']['master']['source']
end

windows_package "Jenkins #{node['jenkins']['master']['version']}" do
  source jenkins_msi_source
  checksum node['jenkins']['master']['msi_checksum'] if node['jenkins']['master']['msi_checksum']
  options node['jenkins']['master']['msi_install_options'] if node['jenkins']['master']['msi_install_options']
end

service 'jenkins' do
  action [:enable, :start]
end

jenkins_service_file = ::File.join(node['jenkins']['master']['home'], 'jenkins.xml')
ruby_block 'update_jenkins_jvm_options' do
  block do
    # This XML update would be nice to do with rexml, but the quotes in the
    # options (e.g. -jar "%BASE%\jenkins.war") get escaped (&quot;) in an
    # undesirable way
    fe = Chef::Util::FileEdit.new(jenkins_service_file)
    fe.search_file_replace(%r{^\s\s<arguments>.*</arguments>$},
                           "  <arguments>#{node['jenkins']['master']['jvm_options']}</arguments>")
    fe.write_file
  end
  not_if do
    require 'rexml/document'
    jenkinsdoc = ::REXML::Document.new ::File.read(jenkins_service_file)
    jenkinsdoc.elements['service'].elements['arguments'].text == node['jenkins']['master']['jvm_options']
  end
  notifies :restart, 'service[jenkins]', :immediately
end
