require 'rails_helper'

describe 'timeline' do
  let(:member) { FactoryBot.create :member }
  let(:friend) { FactoryBot.create :member }
  describe 'followed_by(member)' do
    let!(:planting) { FactoryBot.create :planting, owner: friend, planted_at: 1.day.ago }
    let!(:harvest) { FactoryBot.create :harvest, owner: friend, harvested_at: 2.days.ago }
    before { friend.followers << member }
    subject { TimelineService.followed_query(member) }
    it { expect(subject.first.id).to eq planting.id }
    it { expect(subject.first.event_type).to eq 'planting' }
    it { expect(subject.second.event_id).to eq harvest.id }
    it { expect(subject.sedond.event_type).to eq 'harvest' }
  end

  describe
end
