require 'rails_helper'

describe 'timeline' do
  let(:member) { FactoryBot.create :member }
  let(:friend) { FactoryBot.create :member }
  describe 'followed_by(member)' do
    let!(:planting) { FactoryBot.create :planting, owner: friend, planted_at: 1.day.ago }
    let!(:harvest) { FactoryBot.create :harvest, owner: friend, harvested_at: 2.days.ago }
    before { friend.followers << member }
    subject { TimelineService.followed_query(member) }
    it { expect(subject.first).to eq planting }
    it { expect(TimelineService.resolve_model(subject.second)).to eq harvest }
  end

  describe
end
