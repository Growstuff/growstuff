# frozen_string_literal: true

require 'rails_helper'

describe 'timeline' do
  let(:member) { FactoryBot.create :member }
  let(:friend) { FactoryBot.create :member }

  let!(:friend_planting) { FactoryBot.create :planting, owner: friend, planted_at: 1.day.ago }
  let!(:friend_harvest) { FactoryBot.create :harvest, owner: friend, harvested_at: 2.days.ago }

  let!(:my_seeds) { FactoryBot.create :seed, owner: member, created_at: 4.days.ago }
  let!(:my_post) { FactoryBot.create :post, author: member, created_at: 3.months.ago }

  describe 'a friend you followed' do
    before { friend.followers << member }
    subject { TimelineService.followed_query(member) }
    it { expect(subject.first.id).to eq friend_planting.id }
    it { expect(subject.first.event_type).to eq 'planting' }
    it { expect(subject.second.id).to eq friend_harvest.id }
    it { expect(subject.second.event_type).to eq 'harvest' }
  end

  describe 'your own timeline' do
    subject { TimelineService.member_query(member) }

    it { expect(subject.first.id).to eq my_seeds.id }
    it { expect(subject.first.event_type).to eq 'seed' }
    it { expect(subject.second.id).to eq my_post.id }
    it { expect(subject.second.event_type).to eq 'post' }
  end

  describe "everyone's timeline" do
    subject { TimelineService.query }

    it { expect(subject[0].id).to eq friend_planting.id }
    it { expect(subject[0].event_type).to eq 'planting' }
    it { expect(subject[1].id).to eq friend_harvest.id }
    it { expect(subject[1].event_type).to eq 'harvest' }

    it { expect(subject[2].id).to eq my_seeds.id }
    it { expect(subject[2].event_type).to eq 'seed' }
    it { expect(subject[3].id).to eq my_post.id }
    it { expect(subject[3].event_type).to eq 'post' }
  end
end
