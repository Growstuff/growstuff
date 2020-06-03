# frozen_string_literal: true

module FeatureHelpers
  def fill_autocomplete(field, options = {})
    Crop.reindex
    fill_in field, with: options[:with]
  end

  def select_from_autocomplete(select)
    page.should have_selector('ul.ui-autocomplete li.ui-menu-item a')
    selector = %{ul.ui-autocomplete li.ui-menu-item a:contains("#{select}")}
    page.execute_script " $('#{selector}').mouseenter().click() "
  end

  shared_context 'signed in member' do
    let(:member) { FactoryBot.create :member }
    include_examples 'sign in'
  end
  shared_context 'signed in crop wrangler' do
    let(:member) { FactoryBot.create :crop_wrangling_member }
    include_examples 'sign in'
  end
  shared_context 'signed in admin' do
    let(:member) { FactoryBot.create :admin_member }
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
