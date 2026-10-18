# frozen_string_literal: true

require 'rails_helper'

describe Neighbours do
  subject(:neighbours) { described_class.new(member, scope:) }

  let(:scope) { nil }
  let(:member) { create_located_member('Wellington, NZ', -41.29, 174.78) }

  before { Rails.cache.clear }

  def gardener(latitude:, longitude:)
    create_located_member("Somewhere #{SecureRandom.hex(4)}", latitude, longitude)
  end

  describe '#scope' do
    it 'is auto unless asked for one we have' do
      expect([described_class.new(member, scope: 'bogus').scope, described_class.new(member, scope: 'nearby').scope]).to eq %w(auto nearby)
    end
  end

  describe '#place' do
    it 'is the first part of where they live' do
      expect(neighbours.place).to eq 'Wellington'
    end
  end

  describe '#rings' do
    it 'stops at the first ring when it holds enough people' do
      3.times { gardener(latitude: -41.3, longitude: 174.8) }
      far = gardener(latitude: -36.85, longitude: 174.76) # Auckland

      expect(neighbours.rings.map(&:searched)).to eq [true, false, false]
      expect(neighbours.nearby_members).not_to include(far)
    end

    it 'widens, without repeating anyone, when few are close' do
      close = gardener(latitude: -41.3, longitude: 174.8)
      region = gardener(latitude: -40.9, longitude: 175.0) # Upper Hutt, about 40 km
      far = gardener(latitude: -36.85, longitude: 174.76)

      expect(neighbours.rings.map(&:people)).to eq [[close], [region], [far]]
      expect(neighbours).to be_widened
    end

    it 'leaves out people they follow, themselves and people they block' do
      followed = gardener(latitude: -41.3, longitude: 174.8)
      blocked = gardener(latitude: -41.3, longitude: 174.8)
      member.follows.create!(followed:)
      member.blocks.create!(blocked:)

      expect(neighbours.nearby_members).to be_empty
    end

    it 'is empty without a location' do
      member.update!(location: '', latitude: nil, longitude: nil)
      expect(neighbours.rings).to be_empty
    end

    context 'when looking anywhere' do
      let(:scope) { 'anywhere' }

      it 'has the one ring, nearest first' do
        far = gardener(latitude: -36.85, longitude: 174.76)
        close = gardener(latitude: -41.3, longitude: 174.8)

        expect(neighbours.rings.map(&:people)).to eq [[close, far]]
      end
    end
  end

  describe '#suggestions' do
    let(:garden) { member.gardens.first }
    let(:crop) { create(:crop, name: 'garlic') }
    let(:other) { create(:member) }

    before do
      create(:planting, owner: member, garden:, crop:)
      create(:planting, owner: other, garden: other.gardens.first, crop:)
    end

    it 'suggests people growing the same crops, and says which' do
      expect(neighbours.suggestions.map { |suggestion| [suggestion.member, suggestion.crops] }).to eq [[other, ['garlic']]]
    end

    it 'suggests people their friends follow, and says who' do
      friend = create(:member)
      popular = create(:member)
      member.follows.create!(followed: friend)
      friend.follows.create!(followed: popular)

      suggestion = neighbours.suggestions.find { |candidate| candidate.member == popular }
      expect(suggestion.followed_by).to eq [friend]
    end

    it 'leaves out people they follow or have dismissed' do
      member.member_dismissals.create!(dismissed: other)
      expect(neighbours.suggestions).to be_empty
    end

    it 'is only for the auto scope' do
      expect(described_class.new(member, scope: 'following').suggestions).to be_empty
    end
  end

  describe '#posts' do
    it 'has recent posts by people they follow and people nearby' do
      followed = create(:member)
      member.follows.create!(followed:)
      near = gardener(latitude: -41.3, longitude: 174.8)
      mine = create(:post, author: followed)
      theirs = create(:post, author: near)
      create(:post, author: create(:member))

      expect(neighbours.posts).to contain_exactly(mine, theirs)
    end
  end

  describe '#feed' do
    let(:friend) { create(:member) }

    before { member.follows.create!(followed: friend) }

    it 'groups what people did by day, newest first, tagging how they are connected' do
      near = gardener(latitude: -41.3, longitude: 174.8)
      create(:planting, owner: friend, garden: friend.gardens.first, planted_at: Date.new(2026, 10, 12))
      create(:harvest, owner: near, harvested_at: Date.new(2026, 10, 13))

      days = neighbours.feed
      expect(days.map(&:day)).to eq [Date.new(2026, 10, 13), Date.new(2026, 10, 12)]
      expect(days.flat_map(&:updates).map { |entry| [entry.owner, entry.tag] }).to eq [[near, :near], [friend, :following]]
    end

    it 'puts what one person did in a day into one entry' do
      create(:planting, owner: friend, garden: friend.gardens.first, planted_at: Date.new(2026, 10, 12))
      create(:planting, owner: friend, garden: friend.gardens.first, planted_at: Date.new(2026, 10, 12))

      expect(neighbours.feed.flat_map(&:updates).map { |entry| entry.items.size }).to eq [2]
    end

    it 'leaves out strangers' do
      create(:planting, owner: create(:member), planted_at: Date.new(2026, 10, 12))
      expect(neighbours.feed).to be_empty
    end

    it 'says when there are more days to show' do
      create_list(:planting, Neighbours::FEED_EVENTS + 1, owner: friend, garden: friend.gardens.first, planted_at: Date.new(2026, 10, 12))
      shown = neighbours.feed.flat_map(&:updates).sum { |entry| entry.items.size }
      expect([shown, neighbours.more_feed?]).to eq [Neighbours::FEED_EVENTS, true]
      expect(described_class.new(member, offset: Neighbours::FEED_EVENTS).feed.flat_map(&:updates).sum { |entry| entry.items.size }).to eq 1
    end
  end

  describe '#lede' do
    it 'depends on how many people they follow, and whether nearby widened' do
      gardener(latitude: -41.3, longitude: 174.8)
      expect(neighbours.lede).to eq :none
      member.follows.create!(followed: create(:member))
      expect(described_class.new(member).lede).to eq :few
    end
  end

  describe '#feed photos and layouts' do
    let(:friend) { create(:member) }
    let(:planting) { create(:planting, owner: friend, garden: friend.gardens.first, planted_at: Date.new(2026, 10, 1)) }

    before { member.follows.create!(followed: friend) }

    it 'says a photo is of the planting it is attached to, and groups photos of it' do
      2.times { planting.photos << create(:photo, owner: friend) }

      entry = neighbours.feed.flat_map(&:updates).find { |candidate| candidate.photos.any? }
      expect(entry.photo_groups.map { |subject, count, alone| [subject, count, alone] }).to eq [[planting, 2, false]]
    end

    it 'has gardens whose layout was saved' do
      garden = friend.gardens.first
      garden.update!(layout_saved_at: Time.zone.local(2026, 10, 12, 9, 30))

      items = neighbours.feed.flat_map(&:updates).flat_map(&:items)
      expect(items.map { |item| [item.type, item.record] }).to include(['garden_layout', garden])
    end

    it 'has activities people planned' do
      activity = create(:activity, owner: friend)

      items = neighbours.feed.flat_map(&:updates).flat_map(&:items)
      expect(items.map { |item| [item.type, item.record] }).to include(['activity', activity])
    end

    it 'has plantings that were finished' do
      planting.update!(finished: true, finished_at: Date.new(2026, 10, 5))

      items = neighbours.feed.flat_map(&:updates).flat_map(&:items)
      expect(items.map { |item| [item.type, item.record] }).to include(['planting_finished', planting])
    end

    it 'has plantings that were transplanted into another garden' do
      big_garden = create(:garden, owner: friend)
      planting.transplant_to(big_garden, on: Date.new(2026, 10, 12))

      items = neighbours.feed.flat_map(&:updates).flat_map(&:items)
      expect(items.select { |item| item.type == 'transplant' }.map { |item| item.record.moved_to }).to eq [big_garden]
    end
  end
end
