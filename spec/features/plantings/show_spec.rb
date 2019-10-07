require 'rails_helper'
require 'custom_matchers'

describe 'Display a planting', :js, :elasticsearch do
  before { visit planting_path(planting) }

  context 'Perennial planted long ago' do
    let(:planting) { FactoryBot.create :perennial_planting }
    it { expect(find('.plantingfact--perennial')).to have_text 'Perennial' }
    it { expect(find('.plantingfact--harveststitle')).to have_text 'Harvesting' }
  end

  context 'Perennial finished' do
    let(:planting) do
      FactoryBot.create :perennial_planting, planted_at: 6.years.ago, finished: true, finished_at: 1.year.ago
    end
    it { expect(find('.plantingfact--perennial')).to have_text 'Perennial' }
    it { expect(find('.plantingfact--harveststitle')).to have_text 'Harvested' }
  end

  context 'Annual no predictions' do
    let(:planting) { FactoryBot.create :annual_planting }
    it { expect(find('.plantingfact--harveststitle')).to have_text 'Harvesting' }
  end

  context 'Annual with predicted finish' do
    let(:planting) { FactoryBot.create :predicatable_planting, planted_at: 2.weeks.ago }
    it { expect(find('.plantingfact--weekssinceplanted')).to have_text '2' }
    it { expect(find('.plantingfact--percentagegrown')).to have_text '28%' }
    it { expect(find('.plantingfact--planttedat')).to have_text I18n.l(2.weeks.ago.to_date) }
    it { expect(find('.plantingfact--harveststitle')).to have_text 'Harvesting' }
  end

  context 'Annual finished' do
    let(:planting) do
      FactoryBot.create :annual_planting, planted_at: 100.days.ago, finished: true, finished_at: 1.day.ago
    end
    it { expect(find('.plantingfact--harveststitle')).to have_text 'Harvested' }
  end

  context 'with quantity' do
    let(:planting) { FactoryBot.create :planting, quantity: 100 }
    it { expect(find('.plantingfact--quantity')).to have_text '100' }
    it { expect(find('.plantingfact--harveststitle')).to have_text 'Harvesting' }
  end
end
