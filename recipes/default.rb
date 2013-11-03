# Required by Docker
package 'xz-utils'

# TODO: Remove this once https://github.com/dotcloud/docker/pull/1707 gets sorted out
package 'apt-transport-https'

install_env = { 'STACK_URL' => node['dokku']['stack_url'] }
execute "install_dokku" do
  # TODO: Split change to remote file + execute
  command "wget -qO- https://raw.github.com/imanel/dokku/master/bootstrap.sh | bash"
  environment (install_env)
  not_if { ::File.exists?("/home/dokku") }
end

if domain = node['dokku']['domain']
  file '/home/dokku/VHOST' do
    owner 'dokku'
    group 'dokku'
    content domain
  end
end

if apps = node['dokku']['apps']
  apps.each do |app_name, config|
    directory "/home/dokku/#{app_name}" do
      owner 'dokku'
      group 'dokku'
    end

    if app_env = config['env']
      file "/home/dokku/#{app_name}/ENV" do
        owner  'dokku'
        group  'dokku'
        action :create_if_missing
      end

      app_env.each do |var, value|
        # TODO: Remove old export before writing
        export = "export #{var}='#{value}'"
        execute "echo \"#{export}\" >> /home/dokku/#{app_name}/ENV" do
          user   'dokku'
          not_if { ::File.read("/home/dokku/#{app_name}/ENV") =~ /#{Regexp.escape value}/ }
        end
      end
    end
  end
end

if plugins = node['dokku']['plugins']
  plugins.each do |plugin_name, repo_url|
    execute "plugin_install_#{plugin_name}" do
      command "git clone #{repo_url} #{plugin_name} && cd #{plugin_name} && dokku plugins-install"
      cwd     '/var/lib/dokku/plugins'
      not_if  "test -d /var/lib/dokku/plugins/#{plugin_name}"
    end
  end
end

# TODO: Add SSH key
# TODO: Custom buildpacks (?)
# TODO: nginx configs
# TODO: Support for removing a deployed app
