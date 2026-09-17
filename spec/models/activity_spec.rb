# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Activity do
  describe '.homepage_records' do
    let(:member1) { create(:member) }
    let(:member2) { create(:member) }

    it 'returns the latest activities per owner' do
      create(:activity, owner: member1, created_at: 2.days.ago)
      latest_activity1 = create(:activity, owner: member1, created_at: 1.day.ago)
      latest_activity2 = create(:activity, owner: member2, created_at: Time.current)

      records = described_class.homepage_records(10)
      expect(records).to contain_exactly(latest_activity1, latest_activity2)
    end

    it 'respects the limit' do
      create(:activity, owner: member1)
      create(:activity, owner: member2)

      records = described_class.homepage_records(1)
      expect(records.length).to eq(1)
    end
  end

  describe 'active scope' do
    it 'returns activities that are not finished' do
      active_activity = create(:activity, finished: false)
      finished_activity = create(:activity, finished: true)

      expect(described_class.active).to include(active_activity)
      expect(described_class.active).not_to include(finished_activity)
    end

    it 'treats nil finished as active' do
      activity = create(:activity, finished: nil)
      expect(described_class.active).to include(activity)
    end
  end
end
