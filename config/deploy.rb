require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rbenv'
require 'mina/unicorn'

# require 'mina/rbenv'  # for rbenv support. (https://rbenv.org)
# require 'mina/rvm'    # for rvm support. (https://rvm.io)

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

set :application_name, 'mock_test'
set :domain, '13.127.89.120'
set :deploy_to, '/home/ubuntu/mock_test'
set :repository, 'git@github.com:charlesskariah/mocking.git'
set :branch, 'master'
set :user, 'ubuntu'
set :forward_agent, true
set :port, '22'
set :unicorn_pid, "#{fetch(:deploy_to)}/shared/pids/unicorn.pid"

# Optional settings:
#   set :user, 'foobar'          # Username in the server to SSH to.
#   set :port, '30000'           # SSH port number.
#   set :forward_agent, true     # SSH forward_agent.

# shared dirs and files will be symlinked into the app-folder by the 'deploy:link_shared_paths' step.
 set :shared_dirs, fetch(:shared_dirs, []).push('log')
 set :shared_files, fetch(:shared_files, []).push('config/database.yml', 'config/secrets.yml', 'config/local_env.yml')

# This task is the environment that is loaded for all remote run commands, such as
# `mina deploy` or `mina rake`.
task :remote_environment do
  command %{
    echo "-----> Loading environment"
    #{echo_cmd %[source ~/.bashrc]}
  }
  invoke :'rbenv:load'
  command %[ export PATH="$PATH:$HOME/.rbenv/shims" ]

  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .ruby-version or .rbenv-version to your repository.
  # invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  # invoke :'rvm:use', 'ruby-1.9.3-p125@default'
end

# Put any custom commands you need to run at setup
# All paths in `shared_dirs` and `shared_paths` will be created on their own.
task :setup do
  command %[mkdir -p "#{fetch(:deploy_to)}/shared/log"]
  command %[chmod g+rx,u+rwx "#{fetch(:deploy_to)}/shared/log"]

  command %[mkdir -p "#{fetch(:deploy_to)}/shared/config"]
  command %[chmod g+rx,u+rwx "#{fetch(:deploy_to)}/shared/config"]

  command %[touch "#{fetch(:deploy_to)}/shared/config/database.yml"]
  command  %[echo "-----> Be sure to edit 'shared/config/database.yml'."]

  command %[touch "#{fetch(:deploy_to)}/shared/config/secrets.yml"]
  command %[echo "-----> Be sure to edit 'shared/config/secrets.yml'."]

  command %[touch "#{fetch(:deploy_to)}/shared/config/local_env.yml"]
  command %[echo "-----> Be sure to edit 'shared/config/local_env.yml'."]
  # command %{rbenv install 2.3.0}
end

desc "Deploys the current version to the server."
task :deploy  do
  # uncomment this line to make sure you pushed your local branch to the remote origin
  #invoke :'git:ensure_pushed'
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'

    on :launch do
      invoke :'unicorn:restart'
    end
  end

  # you can use `run :local` to run tasks on local machine before of after the deploy scripts
  # run(:local){ say 'done' }
end

# For help in making your deploy script, see the Mina documentation:
#
#  - https://github.com/mina-deploy/mina/tree/master/docs
