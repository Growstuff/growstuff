module FeatureHelpers

  def fill_autocomplete(field, options = {})
    fill_in field, :with => options[:with]

    sleep 3

    page.execute_script %Q{ $('##{field}').trigger('focus') }
    page.execute_script %Q{ $('##{field}').trigger('keydown') }
    # selector = %Q{ul.ui-autocomplete li.ui-menu-item a:contains("#{options[:select]}")}

    # page.should have_selector('ul.ui-autocomplete li.ui-menu-item a')
    # page.execute_script %Q{ $('#{selector}').trigger('mouseenter').click() }
  end


end

RSpec.configure do |config|
  config.include FeatureHelpers, :type => :feature
end