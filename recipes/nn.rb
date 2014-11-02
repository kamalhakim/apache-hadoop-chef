#include_recipe "hadoop::install"
libpath = File.expand_path '../../../kagent/libraries', __FILE__
require File.join(libpath, 'inifile')

my_ip = my_private_ip()

for script in node[:hadoop][:nn][:scripts]
  template "#{node[:hadoop][:home]}/sbin/#{script}" do
    source "#{script}.erb"
    owner node[:hadoop][:user]
    group node[:hadoop][:group]
    mode 0775
  end
end 


# it is ok if all namenodes format the fs. Unless you add a new one later..

if node[:hadoop][:format].eql? "true"
    bash 'format-nn' do
      user node[:hadoop][:user]
      code <<-EOH
        source /home/#{node[:hadoop][:user]}/.bash_profile
# TODO: if the nn has already been formatted, re-formatting it returns error
#     	#{node[:hadoop][:home]}/sbin/stop-nn.sh 
    	#{node[:hadoop][:home]}/sbin/format-nn.sh
 	EOH
      not_if "test -d #{node[:hadoop][:tmp_dir]}/dfs/data/current/"
    end
end

service "namenode" do
  supports :restart => true, :stop => true, :start => true
  action :nothing
end

template "/etc/init.d/namenode" do
  source "namenode.erb"
  owner node[:hadoop][:user]
  group node[:hadoop][:group]
  mode 0754
  notifies :enable, resources(:service => "namenode"), :immediately
  notifies :restart, resources(:service => "namenode")
end

if node[:kagent][:enabled] == "true" 
  kagent_config "namenode" do
    service "HDFS"
    start_script "#{node[:hadoop][:home]}/sbin/root-start-nn.sh"
    stop_script "#{node[:hadoop][:home]}/sbin/stop-nn.sh"
    init_script "#{node[:hadoop][:home]}/sbin/format-nn.sh"
    config_file "#{node[:hadoop][:conf_dir]}/core-site.xml"
    log_file "#{node[:hadoop][:logs_dir]}/hadoop-#{node[:hadoop][:user]}-namenode-#{node['hostname']}.log"
    pid_file "#{node[:hadoop][:logs_dir]}/hadoop-#{node[:hadoop][:user]}-namenode.pid"
    web_port node[:hadoop][:nn][:http_port]
  end
end