#
# Cookbook Name:: disco
# Recipe:: master
#
# 2012, Dan Crosta
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

include_recipe "disco"

attrs = node["disco"]

template "/etc/init.d/disco-master" do
  owner "root"
  group "root"
  mode "0755"
  variables(
    :disco_user => attrs["user"]
  )
  action :create
end

service "disco-master" do
  action :start
end


template "#{node['etc']['passwd'][attrs['user']]['dir']}/.ssh/config" do
  source "ssh_config.erb"
  owner attrs["user"]
  group attrs["group"]
  mode "0644"
  action :create
end

tmpl = template "/usr/local/var/disco/disco_8989.config" do
  source "disco.config.erb"
  owner attrs["user"]
  group attrs["group"]
  mode "0644"
  variables(
    :slaves => search("node", node["disco"]["slave_search"])
  )
  action :create
  notifies :restart, "service[disco-master]"
  not_if Chef::Config["solo"]
end

if Chef::Config["solo"]
  Chef::Log.info("Did not generate #{tmpl} since you are using chef-solo. You may configure your cluster through Disco's web interface.")
end
