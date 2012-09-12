# encoding: utf-8

require 'rubygems'
#require 'bundler'
#begin
#  Bundler.setup(:default, :development)
#rescue Bundler::BundlerError => e
#  $stderr.puts e.message
#  $stderr.puts "Run `bundle install` to install missing gems"
#  exit e.status_code
#end
require 'rake'
require 'rspec'
require 'rspec/core/rake_task'
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), 'lib'))

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "firts"
  gem.homepage = "http://github.com/dekz/firts"
  gem.license = "Modified BSD License"
  gem.summary = %Q{distributed workers with tuplespace}
  gem.description = %Q{Execute jobs on remote distributed machines}
  gem.email = "jacob@dekz.net"
  gem.authors = ["Jacob Evans"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "firts #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end


desc 'Default: run specs.'
task :default => :spec

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  t.pattern = "./spec/**/*_spec.rb" 
  # Put spec opts in a file named .rspec in root
end



