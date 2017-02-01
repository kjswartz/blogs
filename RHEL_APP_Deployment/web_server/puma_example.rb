#!/usr/bin/env puma

directory '/var/www/<project>/current'
rackup "/var/www/<project>/current/config.ru"
environment 'production'

pidfile "/var/www/<project>/shared/tmp/pids/puma.pid"
state_path "/var/www/<project>/shared/tmp/pids/puma.state"
stdout_redirect '/var/www/<project>/current/log/puma.error.log', '/var/www/<project>/current/log/puma.access.log', true


threads 5,5

bind 'unix:///var/www/<project>/shared/tmp/sockets/<project>-puma.sock'

workers 0



preload_app!


on_restart do
  puts 'Refreshing Gemfile'
  ENV["BUNDLE_GEMFILE"] = "/var/www/<project>/current/Gemfile"
end


on_worker_boot do
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
  end
end

