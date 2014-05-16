namespace :assets do
  desc 'Compile Assets'
  task :compile do
    on roles(:app) do
      within release_path do
        execute :rake, :assets, :compile
      end
    end
  end
end

before 'deploy:restart', 'assets:compile'
