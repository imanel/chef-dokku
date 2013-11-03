include_recipe "dokku"

node[:dokku][:apps].keys.each do |app|
execute "create postgresql database #{app}" do
  command "dokku postgresql:create #{app}"
  user    'dokku'
  cwd     '/home/dokku'
  not_if  "docker ps | grep postgresql/#{app}:latest"
end
