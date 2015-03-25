# Encoding: utf-8
name 'stack_commons'
maintainer 'Rackspace'
maintainer_email 'rackspace-cookbooks@rackspace.com'
license 'Apache 2.0'
description 'provides common supporting features for stacks'
# long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))

version '0.0.46'

depends 'apt'
depends 'build-essential'
depends 'chef-sugar'
depends 'database', '>= 2.3.1'
depends 'java'
depends 'memcached'
depends 'mongodb'
depends 'mysql', '~> 5.0'
depends 'mysql-multi', '~> 1.0'
depends 'mysql2_chef_gem', '~> 1.0'
depends 'newrelic'
depends 'newrelic_meetme_plugin'
depends 'newrelic_plugins'
depends 'nginx'
depends 'openssl', '~> 2.0.0'
depends 'percona-multi'
depends 'pg-multi'
depends 'php'
depends 'platformstack'
depends 'python'
depends 'rabbitmq'
depends 'rackspace_gluster'
depends 'redis-multi'
depends 'uwsgi'
depends 'varnish'
depends 'yum'
depends 'yum-ius'
depends 'yum-epel'
