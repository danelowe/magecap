namespace :compass do
  desc 'Updates stylesheets if necessary from their Sass templates.'
  task :compile do
    on roles(:app) do
      within release_path do
        execute :compass, "compile --output-style nested --force -e production"
      end
#       run_locally("compass clean")
#       run_locally("compass compile --output-style compressed")
#       upload("#{theme_path}/compass_generated_stylesheets",
#         "#{release_path}/#{theme_path}/compass_generated_stylesheets")
#       # Glob is nasty, but the generated_images directory
#       # option isn't supported until Compass 0.12.
#       Dir.glob("#{theme_path}/images/*-s[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f].png").each do|f|
#         upload(f, "#{release_path}/#{f}")
#       end
    end
  end
end

before 'deploy:restart', 'compass:compile'