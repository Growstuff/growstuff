# frozen_string_literal: true

require 'rake'

# Loading the tasks twice appends every action a second time, so each task
# would run twice. Load them once, the first time a task spec needs them.
module RakeTasks
  def self.load
    @load ||= Rails.application.load_tasks || true
  end
end

RSpec.configure do |config|
  config.define_derived_metadata(file_path: %r{/spec/tasks/}) { |metadata| metadata[:type] = :task }
  config.before(:context, type: :task) { RakeTasks.load }
end
