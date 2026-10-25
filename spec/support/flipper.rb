# frozen_string_literal: true

# Features are kept in memory in specs, and all off at the start of each. Tag an
# example group with `flipper: :name` (or a list of names) to have them on.
require 'flipper/test_help'

RSpec.configure do |config|
  config.before do |example|
    Array(example.metadata[:flipper]).each { |name| Flipper.enable(name) }
  end
end
