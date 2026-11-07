# frozen_string_literal: true

require 'rails_helper'

describe PlantingsController, '#show' do
  let(:planting) { create(:planting, planted_at: Date.new(2026, 3, 10)) }
  let(:page) { Capybara.string(response.body) }

  context 'when signed out' do
    before { get planting_path(planting) }

    it 'does not offer label printing' do
      expect(page).to have_no_css('form[data-print-label]')
    end

    it 'does not load the PDF bundle' do
      expect(page).to have_no_css('script[src*="print_label"]', visible: :all)
    end
  end

  shared_examples 'a printable planting label' do
    before { get planting_path(planting) }

    it 'offers one compact label form' do
      expect(page).to have_css('.planting-print-label form[data-print-label]', count: 1)
    end

    it 'shows the form without a disclosure' do
      expect(page).to have_no_css('.planting-print-label details', visible: :all)
    end

    it 'places label printing directly after the crop panel' do
      expect(page).to have_css('.planting-crop + .planting-print-label', visible: :all)
    end

    it 'gives the labels panel a section heading' do
      expect(page).to have_css('.planting-print-label > .section-header h2', text: I18n.t('plantings.show.labels'))
    end

    it 'keeps label printing out of the main planting panel' do
      expect(page).to have_no_css('.planting-detail form[data-print-label]', visible: :all)
    end

    it 'encodes the canonical planting URL' do
      expect(page).to have_css("form[data-url='#{planting_url(planting)}']", visible: :all)
    end

    it 'uses the planting display name' do
      expect(page.find('form[data-print-label]', visible: :all)['data-name']).to eq(planting.display_name)
    end

    it 'includes the planted date' do
      expect(page.find('form[data-print-label]', visible: :all)['data-date']).to eq(
        I18n.t('plantings.print_label.planted_date', date: I18n.l(planting.planted_at))
      )
    end

    it 'offers editable dimensions' do
      expect(page).to have_css('form[data-print-label] input[type="number"]', count: 2, visible: :all)
    end

    it 'uses a planting-specific filename' do
      expect(page).to have_css('form[data-filename="growstuff-planting-label.pdf"]', visible: :all)
    end

    it 'loads the PDF bundle' do
      expect(page).to have_css('script[src*="print_label"]', visible: :all)
    end
  end

  context 'when the owner is signed in' do
    before { sign_in planting.owner }

    it_behaves_like 'a printable planting label'
  end

  context 'when another member is signed in' do
    before { sign_in create(:member) }

    it_behaves_like 'a printable planting label'
  end

  context 'without a planted date' do
    let(:planting) { create(:planting, planted_at: nil) }

    before do
      sign_in planting.owner
      get planting_path(planting)
    end

    it 'uses the print date' do
      expect(page.find('form[data-print-label]', visible: :all)['data-date']).to eq(
        I18n.t('shared.print_label.printed_date', date: I18n.l(Date.current))
      )
    end
  end
end
