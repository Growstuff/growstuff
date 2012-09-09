require 'rake'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :run_tests do
  system("rspec spec/")
	system("rake test")
end

