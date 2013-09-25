if node['jenkins']['node']['ssh_private_key']
  ssh_dir = File.dirname(node['jenkins']['node']['ssh_private_key'])

  directory ssh_dir do
    recursive true
    owner node['jenkins']['node']['user']
    group node['jenkins']['node']['group']
    mode 0700
  end

  execute "Create SSL Certificates" do
    cwd ssh_dir
    command <<-EOH
    ssh-keygen -f #{node['jenkins']['node']['ssh_private_key']} -N ''
    EOH
    creates node['jenkins']['node']['ssh_private_key']
  end

  file node['jenkins']['node']['ssh_private_key'] do
    owner node['jenkins']['node']['user']
    group node['jenkins']['node']['group']
    mode 0600
  end
end
