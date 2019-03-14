# frozen_string_literal: true

require 'rspec/expectations'

RSpec::Matchers.define :have_optional do |expected|
  match do |actual|
    actual.has_selector? "#{expected} + span", text: '(Optional)'
  end
end
