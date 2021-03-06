# Encoding: utf-8
#
# Cookbook Name:: stack_commons
# Recipe:: mysql_base
#
# Copyright 2014, Rackspace Hosting
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

stackname = node['stack_commons']['stackname']

include_recipe 'apt' if node.platform_family?('debian')
include_recipe 'chef-sugar'

# check if they exist, then set demo attributes if needed
# -- it seems bad to be touching webserver attributes here.
webserver = node.deep_fetch(stackname, 'webserver')
node.default[stackname][webserver]['sites'] = node.deep_fetch(stackname, 'demo', webserver, 'sites') if webserver && node.deep_fetch(stackname, 'demo', 'enabled')

# set passwords dynamically...
::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
node.default_unless['stack_commons']['cloud_monitoring']['agent_mysql']['password'] = secure_password
if node['mysql']['server_root_password'] == 'ilikerandompasswords'
  node.set['mysql']['server_root_password'] = secure_password
end

# Provide more verbose error when trying to install 5.6 on < Ubuntu 14.04
if ubuntu_before_trusty? && node['mysql']['version']
  if node['mysql']['version'] == '5.6'
    errmsg = "MySQL 5.6 isn't available on this platform. Please change version."
    Chef::Log.error(errmsg)
    fail errmsg
  end
end

include_recipe 'build-essential'
include_recipe 'mysql::server'
include_recipe 'mysql::client'
include_recipe 'mysql-multi'
mysql2_chef_gem 'default' do
  client_version node['mysql']['version'] if node['mysql']
  action :install
end

connection_info = {
  host: 'localhost',
  username: 'root',
  password: node['mysql']['server_root_password']
}

# add holland user (if holland is enabled)
mysql_database_user 'holland' do
  connection connection_info
  password node['holland']['password']
  host 'localhost'
  privileges [:usage, :select, :'lock tables', :'show view', :reload, :super, :'replication client']
  retries 2
  retry_delay 2
  action [:create, :grant]
  only_if { node.deep_fetch('holland', 'enabled') }
end

mysql_database_user node['stack_commons']['cloud_monitoring']['agent_mysql']['user'] do
  connection connection_info
  password node['stack_commons']['cloud_monitoring']['agent_mysql']['password']
  action 'create'
  only_if { node.deep_fetch('platformstack', 'cloud_monitoring', 'enabled') }
end

# allow the app nodes to connect to mysql
search_add_iptables_rules(
  "tags:#{stackname.gsub('stack', '')}_app_node AND chef_environment:#{node.chef_environment}",
  'INPUT', "-p tcp --dport #{node['mysql']['port']} -j ACCEPT",
  9998,
  'allow app nodes to connect to mysql')

if Chef::Config[:solo]
  Chef::Log.warn('This recipe uses search. Chef Solo does not support search.')
  app_nodes = []
else
  app_nodes = search(:node, "tags:#{stackname.gsub('stack', '')}_app_node AND chef_environment:#{node.chef_environment}")
end

# set sites to nothing if not defined, this is needed for webservers other then apache and nginx
node.default_unless[stackname][node[stackname]['webserver']]['sites'] = {}

# auto-generate databases
node[stackname][node[stackname]['webserver']]['sites'].each do |port, sites|
  # we don't want to create DBs or users and the like on slaves, do we?
  next if includes_recipe?("#{stackname}::mysql_slave")
  # only auto-generate databases if needed
  next unless node[stackname]['db-autocreate']['enabled']
  sites.each do |site_name, site_opts|
    if site_opts.include?('db_autocreate')
      next unless site_opts['db_autocreate']
    end
    # set up the default DB name, user and password
    db_name = "#{site_name[0...58]}_#{port}".gsub(/[^0-9A-Za-z\-\_]/, '')
    node.default_unless[stackname][node[stackname]['webserver']]['sites'][port][site_name]['databases'][db_name]['mysql_user'] = SecureRandom.hex(8) # ~FC047
    node.default_unless[stackname][node[stackname]['webserver']]['sites'][port][site_name]['databases'][db_name]['mysql_password'] = secure_password # ~FC047
    node.default_unless[stackname][node[stackname]['webserver']]['sites'][port][site_name]['databases'][db_name]['privileges'] = %w(select update insert)
    node.default_unless[stackname][node[stackname]['webserver']]['sites'][port][site_name]['databases'][db_name]['global_privileges'] = []

    # need to redefine site_opts because we just added user/passwords to that hash
    site_opts = node[stackname][node[stackname]['webserver']]['sites'][port][site_name]

    # sets up the default, autodefined database(s)
    site_opts['databases'].each do |database, database_opts|
      mysql_database database do
        connection connection_info
        action 'create'
      end

      # allow access if needed
      app_nodes.each do |app_node|
        # db-specific privileges
        mysql_database_user "db #{database} grants on #{app_node}" do
          username database_opts['mysql_user']
          connection connection_info
          password database_opts['mysql_password']
          host best_ip_for(app_node)
          database_name database
          privileges database_opts['privileges']
          retries 2
          retry_delay 2
          action %w(create grant)
        end

        # global privileges (db = "*")
        mysql_database_user "global grants on #{app_node}" do
          username database_opts['mysql_user']
          connection connection_info
          password database_opts['mysql_password']
          host best_ip_for(app_node)
          privileges database_opts['global_privileges']
          retries 2
          retry_delay 2
          action %w(create grant)
          only_if { database_opts['global_privileges'] && !database_opts['global_privileges'].empty? }
        end
      end
    end
  end
end

# user defined databases exist somewhere else
node[stackname]['mysql']['databases'].each do |database, database_opts|
  next if includes_recipe?("#{stackname}::mysql_slave")

  mysql_database database do
    connection connection_info
    action 'create'
  end

  node.default_unless[stackname]['mysql']['databases'][database]['mysql_user'] = ::SecureRandom.hex(8)
  node.default_unless[stackname]['mysql']['databases'][database]['mysql_password'] = secure_password
  node.default_unless[stackname]['mysql']['databases'][database]['privileges'] = %w(select update insert)
  node.default_unless[stackname]['mysql']['databases'][database]['global_privileges'] = []

  # need to redefine database_opts because we just added user/passwords to that hash
  database_opts = node[stackname]['mysql']['databases'][database]

  # allow access if needed
  app_nodes.each do |app_node|
    mysql_database_user "db #{database} grants on #{app_node}" do
      username database_opts['mysql_user']
      connection connection_info
      password database_opts['mysql_password']
      host best_ip_for(app_node)
      database_name database
      privileges database_opts['privileges']
      retries 2
      retry_delay 2
      action %w(create grant)
    end

    # global privileges (db = "*")
    mysql_database_user "global grants on #{app_node}" do
      username database_opts['mysql_user']
      connection connection_info
      password database_opts['mysql_password']
      host best_ip_for(app_node)
      privileges database_opts['global_privileges']
      retries 2
      retry_delay 2
      action %w(create grant)
      only_if { database_opts['global_privileges'] && !database_opts['global_privileges'].empty? }
    end
  end
end
