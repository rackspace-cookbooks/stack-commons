# Encoding: utf-8

require_relative 'spec_helper'

describe 'stack_commons::newrelic' do
  before { stub_resources }
  supported_platforms.each do |platform, versions|
    versions.each do |version|
      # Context for each platform
      context "on #{platform.capitalize} #{version}" do
        context 'pythonstack' do
          let(:chef_run) do
            ChefSpec::SoloRunner.new(platform: platform, version: version, log_level: LOG_LEVEL) do |node|
              node_resources(node)
              node.set['stack_commons']['application_monitoring']['python']['enabled'] = true
            end.converge(described_recipe)
          end

          %w( newrelic::python_agent stack_commons::python newrelic_meetme_plugin).each do |recipe|
            it "includes #{recipe} recipe" do
              expect(chef_run).to include_recipe(recipe)
            end
            it 'upgrades setuptools' do
              expect(chef_run).to upgrade_python_pip('setuptools')
            end
          end
        end

        context 'phpstack' do
          let(:chef_run) do
            ChefSpec::SoloRunner.new(platform: platform, version: version, log_level: LOG_LEVEL) do |node|
              node_resources(node)
              node.set['stack_commons']['application_monitoring']['php']['enabled'] = true
              # https://github.com/escapestudios- cookbooks/newrelic/blob/master/spec/unit/php_agent_spec.rb#L9
              node.set['newrelic']['php_agent']['web_server']['service_name'] = 'stub_service'
            end.converge(described_recipe)
          end
          %w( php newrelic::php_agent newrelic_meetme_plugin).each do |recipe|
            it "includes #{recipe} recipe" do
              expect(chef_run).to include_recipe(recipe)
            end
          end
        end

        context 'tomcatstack' do
          let(:chef_run) do
            ChefSpec::SoloRunner.new(platform: platform, version: version, log_level: LOG_LEVEL) do |node|
              node_resources(node)
              node.set['stack_commons']['application_monitoring']['java']['enabled'] = true
            end.converge(described_recipe)
          end
          %w( newrelic::java_agent newrelic_meetme_plugin).each do |recipe|
            it "includes #{recipe} recipe" do
              expect(chef_run).to include_recipe(recipe)
            end
          end
        end

        context 'memcached' do
          let(:chef_run) do
            ChefSpec::SoloRunner.new(platform: platform, version: version, log_level: LOG_LEVEL) do |node|
              node_resources(node)
            end.converge('memcached', described_recipe)
          end
        end

        context 'rabbitmq' do
          let(:chef_run) do
            ChefSpec::SoloRunner.new(platform: platform, version: version, log_level: LOG_LEVEL) do |node|
              node_resources(node)
              node.set['stack_commons']['webserver'] = 'nginx'
              node.set['stack_commons']['nginx']['sites']['80']['site1']['server_name'] = 'site1'
            end.converge('rabbitmq', described_recipe)
          end
        end

        context 'redis' do
          let(:chef_run) do
            ChefSpec::SoloRunner.new(platform: platform, version: version, log_level: LOG_LEVEL) do |node|
              node_resources(node)
            end.converge('stack_commons::redis_base',  described_recipe)
          end
        end

        context 'nginx without uwsgi' do
          before do
            stub_command('which nginx').and_return(true)
          end
          let(:chef_run) do
            ChefSpec::SoloRunner.new(platform: platform, version: version, log_level: LOG_LEVEL) do |node|
              node_resources(node)
              node.set['nginx']['sites']['chefspecsite']['uwsgi_port'] = '666'
            end.converge('nginx', described_recipe)
          end
          it 'configures nginx with a /server_status' do
            expect(chef_run).to render_file('/etc/nginx/sites-available/monitor.conf').with_content('server-status')
          end
          it 'enables /server_status' do
            expect(chef_run).to run_execute('nxensite monitor.conf')
            expect(chef_run.execute('nxensite monitor.conf')).to notify('service[nginx]').to(:reload)
          end
        end

        context 'nginx and uwsgi' do
          before do
            stub_command('which nginx').and_return(true)
          end
          let(:chef_run) do
            ChefSpec::SoloRunner.new(platform: platform, version: version, log_level: LOG_LEVEL) do |node|
              node_resources(node)
              node.set['stack_commons']['nginx']['sites']['chefspecsite']['uwsgi_port'] = '666'
            end.converge('nginx', 'uwsgi', described_recipe)
          end
          it 'configures nginx with a /server_status' do
            expect(chef_run).to render_file('/etc/nginx/sites-available/monitor.conf').with_content('server-status')
          end
          it 'enables /server_status' do
            expect(chef_run).to run_execute('nxensite monitor.conf')
            expect(chef_run.execute('nxensite monitor.conf')).to notify('service[nginx]').to(:reload)
          end
        end
      end
    end
  end
end
