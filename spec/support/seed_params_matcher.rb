# frozen_string_literal: true

# The page's query params are these, in any order: the seed library keeps the
# params it was given in the order it was given them.
RSpec::Matchers.define :have_seed_params do |expected|
  match do |page|
    page.document.synchronize do
      actual = Rack::Utils.parse_query(URI(page.current_url).query)
      raise Capybara::ExpectationNotMet unless actual == expected.transform_keys(&:to_s).transform_values(&:to_s)

      true
    end
  rescue Capybara::ExpectationNotMet
    false
  end

  failure_message { |page| "expected the address to have the params #{expected}, got #{URI(page.current_url).query}" }
end
