set :application, "dev.growstuff.org"
set :repository,  "https://github.com/Growstuff/growstuff.git"

set :scm, :git
set :branch, "dev"
set :user, "deploy"
set :use_sudo, false
set :deploy_to, "/var/www/#{application}"
set :deploy_via, :remote_cache

role :web, application
role :app, application
role :db,  application, :primary => true # This is where Rails migrations will rue

require "rvm/capistrano"
set :rvm_ruby_string, 'ruby-1.9.3-p194@growstuffdev'
set :rvm_type, :user

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

set :bundle_dir, "/home/deploy/.rvm/gems/ruby-1.9.3-p194@growstuffdev/"
set :bundle_flags, "--deployment"
require 'bundler/capistrano'

# this makes it easier to run rake tasks on the server.
# just "bundle exec cap rake_task" where rake_task is eg. db:migrate

require 'cape'

Cape do
  # Create Capistrano recipes for all Rake tasks.
  mirror_rake_tasks :db
  mirror_rake_tasks 'db:create:all', :roles => :app do |env|
    env['RAILS_ENV'] = rails_env
  end
  mirror_rake_tasks 'db:migrate', :roles => :app do |env|
    env['RAILS_ENV'] = rails_env
  end
  mirror_rake_tasks :assets
end

namespace :deploy do
  task :start do ; end
  task :stop do ; end

  desc "Tell Passenger to restart the app."
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end

  # We keep a partial database.yml (with no production passwords) in git.
  # This replaces it with one that has all the right credentials.

  desc "Symlink shared configs and folders on each release."
  task :symlink_shared do
    run "rm #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end
end

after :deploy, 'db:migrate'

after 'deploy:update_code', 'deploy:symlink_shared'
after 'deploy:finalize_update', 'assets:precompile'
