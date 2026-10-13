# frozen_string_literal: true

require 'rails_helper'

describe MemberDashboard do
  subject(:dashboard) { described_class.new(member, today: Date.new(2026, 10, 12)) }

  let(:member) { create(:member) }
  let(:garden) { member.gardens.first }

  describe '#stage' do
    it 'is new when nothing is planted' do
      expect(dashboard.stage).to eq :new
    end

    it 'is novice in the first year of data' do
      create(:planting, owner: member, garden:, planted_at: Date.new(2026, 9, 1))
      expect(dashboard.stage).to eq :novice
    end

    it 'is veteran once the first planting is over a year old' do
      create(:planting, owner: member, garden:, planted_at: 3.years.ago)
      expect(dashboard.stage).to eq :veteran
    end
  end

  describe 'yearly numbers' do
    before do
      create(:planting, owner: member, garden:, planted_at: Date.new(2026, 3, 1))
      create(:planting, owner: member, garden:, planted_at: Date.new(2026, 4, 1))
      create(:planting, owner: member, garden:, planted_at: Date.new(2025, 4, 1))
    end

    it 'counts plantings this year and last' do
      expect([dashboard.plantings_this_year, dashboard.plantings_last_year]).to eq [2, 1]
    end

    it 'has twelve months of harvest' do
      expect(dashboard.harvest_by_month.size).to eq 12
    end

    it 'counts harvests in a month even when they have no weight' do
      planting = create(:planting, owner: member, garden:, planted_at: Date.new(2026, 3, 1))
      create(:harvest, owner: member, crop: planting.crop, planting:, harvested_at: Date.new(2026, 5, 2), weight_quantity: nil)
      may = dashboard.harvest_by_month.find { |entry| entry[:month] == 5 }
      expect([may[:harvests][:this_year], may[:kilograms][:this_year]]).to eq [1, 0.0]
    end
  end

  describe '#band' do
    it 'is ten degrees centred to the nearest five' do
      member.latitude = -41.3
      expect(dashboard.band).to eq(-45..-35)
    end
  end

  describe '#band_label' do
    it 'names the southern band without a minus sign' do
      member.latitude = -41.3
      expect(dashboard.band_label).to eq '35–45°S'
    end
  end

  describe '#at_latitude' do
    # The test cache is a file store that outlives the run, so give each
    # example an empty one.
    before { allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new) }

    it 'is nil when we do not know where they are' do
      member.latitude = nil
      expect(dashboard.at_latitude).to be_nil
    end

    it 'leads with the crops planted at that latitude this month' do
      member.update_columns(latitude: -41.3, longitude: 174.7)
      crop = create(:crop, name: 'broad bean')
      other = create(:garden)
      other.update_columns(latitude: -40.0, longitude: 174.0)
      create(:planting, crop:, garden: other, owner: other.owner, planted_at: Date.new(2024, 10, 3))
      leader = dashboard.at_latitude.first[:planting].first
      expect(leader).to include(name: 'broad bean', count: 1)
    end
  end

  describe '#easy_to_sow' do
    let(:crop) { create(:crop, name: 'broad bean') }

    before do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      member.update_columns(latitude: -41.3, longitude: 174.7)
      other = create(:garden)
      other.update_columns(latitude: -40.0, longitude: 174.0)
      create(:planting, crop:, garden: other, owner: other.owner, planted_at: Date.new(2024, 10, 3))
    end

    it 'suggests what gardeners at that latitude are planting this month' do
      expect(dashboard.easy_to_sow).to eq [crop]
    end

    it 'leaves out crops they said are not for them' do
      create(:crop_dismissal, member:, crop:)
      expect(dashboard.easy_to_sow).to eq []
    end

    it 'leaves out crops they are already growing' do
      create(:planting, owner: member, garden:, crop:, planted_at: Date.new(2026, 9, 1))
      expect(dashboard.easy_to_sow).to eq []
    end

    it 'counts what they have hidden' do
      create(:crop_dismissal, member:, crop:)
      expect(dashboard.dismissed_count).to eq 1
    end
  end

  describe '#planted_this_time_last_year' do
    it 'names what they planted around now a year ago, most planted first' do
      basil = create(:crop, name: 'basil')
      chives = create(:crop, name: 'chives')
      create(:planting, owner: member, garden:, crop: chives, planted_at: Date.new(2025, 10, 1))
      2.times { create(:planting, owner: member, garden:, crop: basil, planted_at: Date.new(2025, 10, 20)) }
      expect(dashboard.planted_this_time_last_year).to eq %w(basil chives)
    end

    it 'leaves out what they planted at other times of year' do
      create(:planting, owner: member, garden:, planted_at: Date.new(2025, 3, 1))
      expect(dashboard.planted_this_time_last_year).to eq []
    end
  end

  describe '#activity' do
    it 'shows people they follow, marked as followed' do
      friend = create(:member)
      create(:planting, owner: friend, garden: friend.gardens.first)
      member.followed << friend
      expect(dashboard.activity.map(&:following)).to eq [true]
    end
  end
end
