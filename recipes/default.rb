#
# Cookbook Name:: disco
# Recipe:: default
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

attrs = node["disco"]

directory attrs["checkout"] do
  owner attrs["user"]
  group attrs["group"]
  action :create
  recursive true
end


include_recipe "build-essential"
package "erlang"


[ "/usr/local/var/disco", "/usr/local/var/disco/ddfs" ].each do |dir|
  directory dir do
    owner attrs["user"]
    group attrs["group"]
    action :create
    recursive true
  end
end

execute "chown-disco-data-dir" do
  command "chown -R #{attrs['user']}:#{attrs['group']} /usr/local/var/disco"
  action :nothing
end

# Make logs seem to be in a more convenient spot
link "/var/log/disco" do
  to "/usr/local/var/disco/log"
end

execute "install-disco" do
  command "make install"
  cwd attrs["checkout"]
  action :nothing
end

git attrs["checkout"] do
  repository attrs["repository"]
  revision attrs["revision"]

  user attrs["user"]
  group attrs["group"]

  action :sync
  notifies :run, "execute[install-disco]"
  notifies :run, "execute[chown-disco-data-dir]"
end

file "#{node['etc']['passwd'][attrs['user']]['dir']}/.erlang.cookie" do
  owner attrs["user"]
  group attrs["group"]
  mode "0400"
  content node["erlang"]["magic_cookie"]
end

cookbook_file "#{node['etc']['passwd'][attrs['user']]['dir']}/.ssh/id_rsa" do
  source "id_rsa_disco"
  owner attrs["user"]
  mode "0600"
  action :create
  backup 0
end
# TODO the public key is deployed by dcrosta::users


# web UI
simple_iptables_rule "disco" do
  rule "--proto tcp --dport 8989"
  jump "ACCEPT"
end

# DDFS
simple_iptables_rule "disco" do
  rule "--proto tcp --dport 8990"
  jump "ACCEPT"
end

["tcp", "udp"].each do |proto|
  # erlang port mapper
  simple_iptables_rule "disco" do
    rule "--proto #{proto} --dport 4369"
    jump "ACCEPT"
  end

  # erlang slave ports
  simple_iptables_rule "disco" do
    rule "--proto #{proto} --dport 30000:65535"
    jump "ACCEPT"
  end
end
