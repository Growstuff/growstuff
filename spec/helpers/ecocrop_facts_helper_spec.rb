# frozen_string_literal: true

require 'rails_helper'

describe EcocropFactsHelper do
  describe '#ecocrop_facts' do
    subject(:facts) { helper.ecocrop_facts(data) }

    let(:data) do
      build(:ecocrop_data, topmn: 18, topmx: 32, tmin: 7, tmax: nil, ropmn: nil, ropmx: nil, rmin: nil, rmax: nil,
                           phopmn: 5.5, phopmx: 7.0, gmin: 60, gmax: 120, altmx: 2000, liopmn: 'light', liopmx: 'light')
    end

    def card(icon) = facts.find { |fact| fact[:icon] == icon }
    def rows(icon) = card(icon)[:rows].to_h { |row| [row[:label], row[:value]] }

    it('combines optimal and absolute temperature in one card') do
      expect(rows('thermometer-half')).to eq('Optimal temperature' => '18–32 °C', 'Absolute temperature' => '7–? °C')
    end

    it('drops trailing zeros from pH') { expect(rows('flask')['Optimal soil pH']).to eq '5.5–7' }
    it('leaves out a pH range EcoCrop has nothing on') { expect(rows('flask')).not_to have_key('Absolute soil pH') }
    it('gives the crop cycle in days') { expect(card('calendar-alt')[:rows]).to eq [{ value: '60–120 days' }] }
    it('gives the altitude') { expect(card('mountain')[:rows]).to eq [{ value: '2000 m' }] }
    it('names one light level once') { expect(card('sun')[:rows]).to eq [{ value: 'light' }] }
    it('titles a card with one figure') { expect(card('sun')[:title]).to eq 'Optimal light' }
    it('leaves out what EcoCrop has nothing on') { expect(card('cloud-rain')).to be_nil }

    context 'without a record' do
      let(:data) { nil }

      it('has no facts') { expect(facts).to be_empty }
    end
  end
end
