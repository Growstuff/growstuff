require 'rake'
begin
  require 'rspec/core/rake_task'
  task(:spec).clear
  RSpec::Core::RakeTask.new(spec: 'db:test:prepare') do |t|
    t.verbose = false
  end
rescue LoadError
end
