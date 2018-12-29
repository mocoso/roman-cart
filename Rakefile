require 'rspec/core'
require 'rspec/core/rake_task'

task :default => :spec

desc "Run all specs in spec directory (excluding plugin specs)"
RSpec::Core::RakeTask.new(:spec)

task :deploy => ['deploy:deploy_and_cleanup', 'deploy:smoke_test']

namespace :deploy do
  task :bundle_for_deployment do
    sh 'bundle install --deployment --without development'
  end

  task :deploy_and_cleanup => :bundle_for_deployment do
    sh 'sls deploy'
    sh 'rm -rf .bundle'
  end

  task :smoke_test do
    url = `sls info | grep GET |  cut -d' ' -f5`
    sh "curl #{url}"
    puts "\n\n\n"
  end
end
