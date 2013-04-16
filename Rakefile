require "bundler/gem_tasks"
require "rocco/tasks"
require 'rspec/core/rake_task'
require 'rake/clean'

RSpec::Core::RakeTask.new('spec')
task :default => :spec # to make it default

desc "Generate Rocco Documentation"
task :rocco
Rocco::make 'doc/', 'lib/**/*.rb', {
  :stylesheet => 'docco.css'
}

task :rocco
directory 'doc/'

file 'doc/lib/index.html' => 'doc/lib/gi_cat_driver.html' do |f|
  mv 'doc/lib/gi_cat_driver.html', 'doc/lib/index.html'
end
task :rocco => 'doc/lib/index.html'
CLEAN.include 'doc/lib/index.html'

