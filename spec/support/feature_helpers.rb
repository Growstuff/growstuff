module FeatureHelpers

  def fill_autocomplete(field, options = {})
    fill_in field, :with => options[:with]

    page.execute_script %Q{ $('##{field}').trigger('focus'); }
    page.execute_script %Q{ $('##{field}').trigger('keydown'); }
  end

end

RSpec.configure do |config|
  config.include FeatureHelpers, :type => :feature
end