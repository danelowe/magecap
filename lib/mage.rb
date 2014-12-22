load Gem.find_files('nonrails.rb').last.to_s

namespace :mage do
  desc <<-DESC
Clear the Magento Cache
  DESC
  task :clean_cache do
    on roles(:web, :app) do
      run "cd #{current_path}#{fetch(:app_webroot)} && php -r \"require_once('app/Mage.php'); Mage::app()->cleanCache();\""
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

after 'deploy:cleanup', 'mage:clean_cache'
