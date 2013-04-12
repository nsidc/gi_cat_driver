require "bundler/gem_tasks"
require "rocco/tasks"
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new('spec')
task :default => :spec # to make it default

desc "Generate Rocco Documentation"
Rocco::make 'doc/', 'lib/**/*.rb', {
  :language => 'ruby',
  :stylesheet => 'docco.css'
}
