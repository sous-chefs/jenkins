user_dir = "#{node['jenkins']['server']['home']}/users/testuser"

directory user_dir do
  recursive true
  owner node['jenkins']['server']['user']
  mode 0755
end

template "#{user_dir}/config.xml" do
  source      "testuser_config.xml.erb"
  owner       node['jenkins']['server']['user']
  mode        '0600'
  notifies :restart, "service[jenkins]", :immediately
  notifies :create, "ruby_block[block_until_operational]", :immediately
end
