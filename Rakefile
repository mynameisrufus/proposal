require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rubocop/rake_task'
require 'rdoc/task'

RuboCop::RakeTask.new

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Proposal'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.md')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

APP_RAKEFILE = File.expand_path("../test/dummy/Rakefile", __FILE__)

load 'rails/tasks/engine.rake'

load 'rails/tasks/statistics.rake'

Bundler::GemHelper.install_tasks

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end

task default: [:test, :rubocop]
