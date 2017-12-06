module FeatureHelpers
  def fill_autocomplete(field, options = {})
    fill_in field, with: options[:with]

    page.execute_script " $('##{field}').trigger('focus'); "
    page.execute_script " $('##{field}').trigger('keydown'); "
  end

  def select_from_autocomplete(select)
    page.should have_selector('ul.ui-autocomplete li.ui-menu-item a')
    selector = %{ul.ui-autocomplete li.ui-menu-item a:contains("#{select}")}
    page.execute_script " $('#{selector}').mouseenter().click() "
  end
end

RSpec.configure do |config|
  config.include FeatureHelpers, type: :feature
end
