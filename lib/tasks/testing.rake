require 'rake'
begin
  require 'rspec/core/rake_task'
  task(:spec).clear
  RSpec::Core::RakeTask.new(spec: ['db:create', 'db:test:prepare']) do |t|
    t.verbose = false
  end
rescue LoadError
end

task :static do
  system('script/check_static')
end

task default: [:static, :spec]
