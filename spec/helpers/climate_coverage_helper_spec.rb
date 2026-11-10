# frozen_string_literal: true

require 'rails_helper'

describe ClimateCoverageHelper do
  describe 'ICONS' do
    it 'has an icon for every status' do
      expect(described_class::ICONS.keys).to match_array(ClimateCoverage::STATUSES)
    end

    it 'gives each status its own icon' do
      expect(described_class::ICONS.values.uniq.size).to eq ClimateCoverage::STATUSES.size
    end
  end

  describe 'BADGES' do
    it 'has a badge for every status' do
      expect(described_class::BADGES.keys).to match_array(ClimateCoverage::STATUSES)
    end
  end

  describe '#climate_status_badge' do
    subject(:badge) { Capybara.string(helper.climate_status_badge(ClimateCoverage::STALE)) }

    it { expect(badge).to have_css('.badge i.fa-clock[aria-hidden]') }
  end
end
