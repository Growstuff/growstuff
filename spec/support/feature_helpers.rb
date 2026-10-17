# frozen_string_literal: true

module FeatureHelpers
  def fill_autocomplete(field, options = {})
    Crop.reindex
    fill_in field, with: options[:with]
  end

  # Opens every garden on the gardens list, as only the first starts open.
  def open_all_gardens
    page.assert_selector '.garden-card'
    page.all('.garden-card:not([open]) > summary').each(&:click)
  end

  def visit_gardens_open
    visit gardens_path
    open_all_gardens
  end

  def select_from_autocomplete(select)
    page.should have_css('ul.ui-autocomplete li.ui-menu-item a')
    selector = %{ul.ui-autocomplete li.ui-menu-item a:contains("#{select}")}
    page.execute_script " $('#{selector}').mouseenter().click() "
  end

  shared_context 'signed in member' do
    let(:member) { create(:member) }

    include_examples 'sign in'
  end

  shared_context 'signed in crop wrangler' do
    let(:member) { create(:crop_wrangling_member) }

    include_examples 'sign in'
  end

  shared_context 'signed in admin' do
    let(:member) { create(:admin_member) }

    include_examples 'sign in'
  end

  shared_context 'sign in' do
    before { sign_in member }
    after { sign_out member }
  end
end

RSpec.configure do |config|
  config.include FeatureHelpers, type: :feature
end
