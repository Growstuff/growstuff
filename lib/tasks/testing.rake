# frozen_string_literal: true

require 'rake'
begin
  require 'rspec/core/rake_task'
  task(:spec).clear
  RSpec::Core::RakeTask.new(spec: ['db:create',
                                   'db:test:prepare',
                                   'assets:precompile']) do |t|
    t.verbose = false
  end
rescue LoadError
end

desc "Run static code-quality checks"
task :static do
  system('script/check_static')
end

namespace :spec do
  desc "Run only unit tests"
  task unit: ['jasmine:ci'] do
    suites = %w(controllers helpers lib mailers models requests routing views)
    system('rspec', *suites.collect { |s| "spec/#{s}" })
  end
end

task default: [:static, :spec, 'jasmine:ci']
