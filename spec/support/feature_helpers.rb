module FeatureHelpers

  def fill_autocomplete(field, options = {})
    fill_in field, :with => options[:with]

    page.execute_script %Q{ $('##{field}').trigger('focus') }
    page.execute_script %Q{ $('##{field}').trigger('keydown') }
  end

  def select_from_autocomplete(selection)
    selector = %Q{ul.ui-autocomplete li.ui-menu-item a:contains("#{selection}")}
    page.execute_script %Q{ $('#{selector}').trigger('mouseenter').click() }
  end


end

RSpec.configure do |config|
  config.include FeatureHelpers, :type => :feature
end