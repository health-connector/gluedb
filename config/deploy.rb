set :application, "DCHBX GlueDB"
# set :deploy_via, :remote_cache
# set :sudo, "sudo -u nginx"
set :scm, :git
set :repository,  "git@github.com:dchbx/gluedb.git"
set :branch,      "release-1.1"
set :rails_env,       "production"
set :deploy_to,       "/var/www/deployments/gluedb"
set :deploy_via, :copy


set :user, "nginx"
set :use_sudo, false
set :default_shell, "bash -l"
# set :user, "deployer"
# set :password, 'kermit12'
# set :ssh_options, {:forward_agent => true, :keys=>[File.join(ENV["HOME"], "ec2", "AWS-dan.thomas-me.com", "ipublic-key.pem")]}

role :web, "10.83.85.127"
role :app, "10.83.85.127"
role :db,  "10.83.85.127", :primary => true        # This is where Rails migrations will run
# role :db,  "ec2-50-16-240-48.compute-1.amazonaws.com"                          # your slave db-server here

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

default_run_options[:pty] = true  # prompt for sudo password, if needed
after "deploy:restart", "deploy:cleanup_old"  # keep only last 5 releases
before 'deploy:assets:precompile', 'deploy:ensure_gems_correct'

namespace :deploy do

  desc "Make sure bundler doesn't try to load test gems."
  task :ensure_gems_correct do
    run "cp -f #{deploy_to}/shared/Gemfile.lock #{release_path}/Gemfile.lock"
    run "mkdir -p #{release_path}/.bundle"
    run "cp -f #{deploy_to}/shared/.bundle/config #{release_path}/.bundle/config"
  end

  desc "create symbolic links to project nginx, unicorn and database.yml config and init files"
  task :finalize_update do
    run "cp #{deploy_to}/shared/config/mongoid.yml #{release_path}/config/mongoid.yml"
    run "cp #{deploy_to}/shared/config/exchange.yml #{release_path}/config/exchange.yml"
    run "ln -s #{deploy_to}/shared/pids #{release_path}/pids"
  end
  
  desc "Restart nginx and unicorn"
  task :restart, :except => { :no_release => true } do
    sudo "service nginx restart"
    sudo "service unicorn restart"
    sudo "service bluepill_glue restart"
  end

  desc "Start nginx and unicorn"
  task :start, :except => { :no_release => true } do
    run "#{try_sudo} service nginx start"
    run "#{try_sudo} service unicorn start"
  end

  desc "Stop nginx and unicorn"
  task :stop, :except => { :no_release => true } do
    run "#{try_sudo} service unicorn stop"
    run "#{try_sudo} service nginx stop"
  end  

  task :cleanup_old, :except => {:no_release => true} do
    count = fetch(:keep_releases, 5).to_i
    run "ls -1dt #{releases_path}/* | tail -n +#{count + 1} | xargs rm -rf"
  end

end
