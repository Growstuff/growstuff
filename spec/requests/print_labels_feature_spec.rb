# frozen_string_literal: true

require 'rails_helper'

describe 'Print labels with the feature disabled' do
  let(:planting) { create(:planting) }
  let(:page) { Capybara.string(response.body) }

  before { sign_in planting.owner }

  context 'when viewing a planting' do
    before { get planting_path(planting) }

    it 'hides the label section' do
      expect(page).to have_no_css('.planting-print-label')
    end

    it 'does not load the PDF bundle' do
      expect(page).to have_no_css('script[src*="print_label"]', visible: :all)
    end
  end

  context 'when viewing a garden' do
    before { get garden_path(planting.garden) }

    it 'hides label printing' do
      expect(page).to have_no_css('form[data-print-label]', visible: :all)
    end

    it 'does not load the PDF bundle' do
      expect(page).to have_no_css('script[src*="print_label"]', visible: :all)
    end
  end

  context 'when editing a profile' do
    before { get edit_member_registration_path }

    it 'hides label-size preferences' do
      expect(page).to have_no_css('[data-label-size-preferences]', visible: :all)
    end
  end
end
