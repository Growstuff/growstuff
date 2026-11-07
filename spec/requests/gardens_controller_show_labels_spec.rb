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
      expect(page).to have_css('.garden-about details.print-label form[data-print-label]', count: 1, visible: :all)
    end

    it 'keeps label printing out of the main garden panel' do
      expect(page).to have_no_css('.garden-detail form[data-print-label]', visible: :all)
    end

    it 'encodes the canonical garden URL' do
      expect(page).to have_css("form[data-url='#{garden_url(garden)}']", visible: :all)
    end

    it 'omits the print date' do
      expect(page.find('form[data-print-label]', visible: :all)['data-date']).to eq('')
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

  context 'with a saved label preference' do
    before do
      sign_in create(:member, label_width_mm: '62', label_height_mm: '29')
      get garden_path(garden)
    end

    it 'defaults to the viewing member\'s width' do
      expect(page).to have_css('input[name="width"][value="62"]', visible: :all)
    end

    it 'defaults to the viewing member\'s height' do
      expect(page).to have_css('input[name="height"][value="29"]', visible: :all)
    end
  end
end
