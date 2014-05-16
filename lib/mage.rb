load Gem.find_files('nonrails.rb').last.to_s

# =========================================================================
# These variables MUST be set in the client capfiles. If they are not set,
# the deploy will fail with an error.
# =========================================================================
# _cset(:app_symlinks) {
#   abort "Please specify an array of symlinks to shared resources, set :app_symlinks, ['/media', ./. '/staging']"
# }
# _cset(:app_shared_dirs) {
#   abort "Please specify an array of shared directories to be created, set :app_shared_dirs"
# }
# _cset(:app_shared_files) {
#   abort "Please specify an array of shared files to be symlinked, set :app_shared_files"
# }
#
# _cset :compile, false
# _cset :app_webroot, ''

namespace :mage do
  desc <<-DESC
Prepares one or more servers for deployment of Magento. Before you can use any \
of the Capistrano deployment tasks with your project, you will need to \
make sure all of your servers have been prepared with `cap deploy:setup'. When \
you add a new server to your cluster, you can easily run the setup task \
on just that server by specifying the HOSTS environment variable:

$ cap HOSTS=new.server.com mage:setup

It is safe to run this task on servers that have already been set up; it \
will not destroy any deployed revisions or data.
  DESC
  task :setup do
    on roles(:web, :app) do
      if app_shared_dirs
        app_shared_dirs.each { |link| run "#{try_sudo} mkdir -p #{shared_path}#{link} && #{try_sudo} chmod g+w #{shared_path}#{link}"}
      end
      if app_shared_files
        app_shared_files.each { |link| run "#{try_sudo} touch #{shared_path}#{link} && #{try_sudo} chmod g+w #{shared_path}#{link}" }
      end
    end
  end

  desc <<-DESC
Touches up the released code. This is called by update_code \
after the basic deploy finishes.

Any directories deployed from the SCM are first removed and then replaced with \
symlinks to the same directories within the shared location.
  DESC
  task :finalize_update do
    on roles(:web, :app) do
      run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)

      if app_symlinks
        # Remove the contents of the shared directories if they were deployed from SCM
        app_symlinks.each { |link| run "#{try_sudo} rm -rf #{latest_release}#{link}" }
        # Add symlinks the directoris in the shared location
        app_symlinks.each { |link| run "ln -nfs #{shared_path}#{link} #{latest_release}#{link}" }
      end

      if app_shared_files
        # Remove the contents of the shared directories if they were deployed from SCM
        app_shared_files.each { |link| run "#{try_sudo} rm -rf #{latest_release}/#{link}" }
        # Add symlinks the directoris in the shared location
        app_shared_files.each { |link| run "ln -s #{shared_path}#{link} #{latest_release}#{link}" }
      end
    end
  end

  desc <<-DESC
Clear the Magento Cache
  DESC
  task :cc do
    on roles(:web, :app) do
      run "cd #{current_path}#{app_webroot} && php -r \"require_once('app/Mage.php'); Mage::app()->cleanCache();\""
    end
  end

  desc <<-DESC
Disable the Magento install by creating the maintenance.flag in the web root.
  DESC
  task :disable do
    on roles(:web) do
      run "cd #{current_path}#{app_webroot} && touch maintenance.flag"
    end
  end

  desc <<-DESC
Enable the Magento stores by removing the maintenance.flag in the web root.
  DESC
  task :enable do
    on roles(:web) do
      run "cd #{current_path}#{app_webroot} && rm -f maintenance.flag"
    end
end

  desc <<-DESC
Run the Magento compiler
  DESC
  task :compiler do
    on roles(:web, :app) do
      if fetch(:compile, true)
        run "cd #{current_path}#{app_webroot}/shell && php -f compiler.php -- compile"
      end
    end
  end

  desc <<-DESC
Enable the Magento compiler
  DESC
  task :enable_compiler do
    on roles(:web, :app) do
      run "cd #{current_path}#{app_webroot}/shell && php -f compiler.php -- enable"
    end
  end

  desc <<-DESC
Disable the Magento compiler
  DESC
  task :disable_compiler do
    on roles(:web, :app) do
      run "cd #{current_path}#{app_webroot}/shell && php -f compiler.php -- disable"
    end
  end

  desc <<-DESC
Run the Magento indexer
  DESC
  task :indexer do
    on roles(:web, :app) do
      run "cd #{current_path}#{app_webroot}/shell && php -f indexer.php -- reindexall"
    end
  end

  desc <<-DESC
Clean the Magento logs
  DESC
  task :clean_log do
    on roles(:web, :app) do
      run "cd #{current_path}#{app_webroot}/shell && php -f log.php -- clean"
    end
  end
end

# after 'deploy:setup', 'mage:setup'
after 'deploy:finalize_update', 'mage:finalize_update'
# after 'deploy:create_symlink', 'mage:compiler'