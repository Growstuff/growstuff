# frozen_string_literal: true

require 'rails_helper'

describe GardensController, '#show' do
  let(:garden) { create(:garden) }
  let(:page) { Capybara.string(response.body) }

  context 'when signed out' do
    before { get garden_path(garden) }

    it 'does not offer label printing' do
      expect(page).to have_no_css('form[data-print-label]')
    end

    it 'does not load the PDF bundle' do
      expect(page).to have_no_css('script[src*="print_label"]', visible: :all)
    end
  end

  shared_examples 'a printable garden label' do
    before { get garden_path(garden) }

    it 'offers one compact label form' do
      expect(page).to have_css('details.print-label form[data-print-label]', count: 1, visible: :all)
    end

    it 'encodes the canonical garden URL' do
      expect(page).to have_css("form[data-url='#{garden_url(garden)}']", visible: :all)
    end

    it 'offers a width in millimetres' do
      expect(page).to have_css('input[name="width"][type="number"][value="50"]', visible: :all)
    end

    it 'offers a height in millimetres' do
      expect(page).to have_css('input[name="height"][type="number"][value="30"]', visible: :all)
    end

    it 'loads the PDF bundle' do
      expect(page).to have_css('script[src*="print_label"]', visible: :all)
    end
  end

  context 'when the owner is signed in' do
    before { sign_in garden.owner }

    it_behaves_like 'a printable garden label'
  end

  context 'when another member is signed in' do
    before { sign_in create(:member) }

    it_behaves_like 'a printable garden label'
  end

  context 'when the garden is inactive' do
    let(:garden) { create(:garden, active: false) }

    before { sign_in garden.owner }

    it_behaves_like 'a printable garden label'
  end
end
