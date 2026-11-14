# frozen_string_literal: true

require 'rails_helper'

describe StallPlanting do
  subject(:gift) { build(:stall_planting) }

  it { is_expected.to be_valid }

  describe '#recipient' do
    it 'is lower case' do
      gift.recipient = ' Neighbour@Example.COM '
      gift.validate
      expect(gift.recipient).to eq 'neighbour@example.com'
    end

    it 'must be an email address for an email' do
      gift.recipient = 'not an address'
      expect(gift).not_to be_valid
    end

    it 'gets a leading @ for a Fediverse handle' do
      gift = build(:stall_planting, recipient_kind: 'mastodon', recipient: 'alice@mastodon.social')
      gift.validate
      expect(gift.recipient).to eq '@alice@mastodon.social'
    end

    it 'must name a server for a Fediverse handle' do
      expect(build(:stall_planting, recipient_kind: 'mastodon', recipient: '@alice')).not_to be_valid
    end

    it 'gets the default domain for a short Bluesky handle' do
      gift = build(:stall_planting, recipient_kind: 'bluesky', recipient: '@Alice')
      gift.validate
      expect(gift.recipient).to eq 'alice.bsky.social'
    end
  end

  describe 'with a planting that is not the stall owner\'s' do
    subject(:gift) { build(:stall_planting, planting: create(:planting)) }

    it { is_expected.not_to be_valid }
  end

  describe 'with a finished planting' do
    subject(:gift) { build(:stall_planting, planting: create(:finished_planting)) }

    it { is_expected.not_to be_valid }
  end

  describe 'when created' do
    before { gift.save! }

    it 'takes the planting out of the active ones' do
      expect(Planting.active).not_to include(gift.planting)
    end

    it 'takes the planting out of the current ones' do
      expect(Planting.current).not_to include(gift.planting)
    end

    it 'leaves the planting unfinished, so it stays out of the medians' do
      expect(gift.planting.reload.finished?).to be false
    end

    it 'marks the planting as given away' do
      expect(gift.planting.reload).to be_given_away
    end
  end

  describe '.waiting_for' do
    let(:member) { create(:member, email: 'neighbour@example.com') }

    it 'finds a planting given to their email address' do
      gift = create(:stall_planting)
      expect(described_class.waiting_for(member)).to eq [gift]
    end

    it 'finds one given to their email address however it was capitalised' do
      gift = create(:stall_planting, recipient: 'Neighbour@Example.com')
      expect(described_class.waiting_for(member)).to eq [gift]
    end

    it 'leaves out one given to someone else' do
      create(:stall_planting, recipient: 'other@example.com')
      expect(described_class.waiting_for(member)).to be_empty
    end

    it 'finds one given to a Fediverse handle they signed in with' do
      create(:authentication, member:, provider: 'mastodon', uid: '1@mastodon.social', name: '@Alice@mastodon.social')
      gift = create(:stall_planting, :mastodon)
      expect(described_class.waiting_for(member)).to eq [gift]
    end

    it 'finds one given to a Bluesky handle they signed in with' do
      create(:authentication, member:, provider: 'bluesky', uid: 'did:plc:abcdefghijklmnopqrstuvwx', name: 'alice.bsky.social')
      gift = create(:stall_planting, :bluesky)
      expect(described_class.waiting_for(member)).to eq [gift]
    end

    it 'leaves out a handle only written on their profile' do
      member.update!(bluesky_handle: 'alice.bsky.social')
      create(:stall_planting, :bluesky)
      expect(described_class.waiting_for(member)).to be_empty
    end

    it 'leaves out one already claimed' do
      create(:stall_planting, claimed_at: Time.zone.now)
      expect(described_class.waiting_for(member)).to be_empty
    end
  end

  describe '#claim' do
    subject(:claim) { gift.claim(member, garden) }

    let(:gift) { create(:stall_planting) }
    let(:giver) { gift.stall.member }
    let(:member) { create(:member, email: 'neighbour@example.com') }
    let(:garden) { member.gardens.first }
    let(:planting) { gift.planting.reload }

    it { is_expected.to be true }

    context 'when claimed' do
      before { claim }

      it 'moves the planting to the member' do
        expect(planting.owner).to eq member
      end

      it 'puts it in their garden' do
        expect(planting.garden).to eq garden
      end

      it 'makes it active again' do
        expect(Planting.active).to include(planting)
      end

      it 'keeps a record of the giver\'s garden' do
        expect(planting.histories.size).to eq 1
      end

      it 'says it was a gift from the giver' do
        expect(planting.seedling).to have_attributes(source: 'gift', supplier: giver.to_s)
      end

      it 'is recorded as claimed by them' do
        expect(gift.reload).to have_attributes(claimed_by: member)
      end

      it 'stays on the giver\'s stall as given away' do
        expect(giver.stall.stall_plantings).to eq [gift]
      end
    end

    context 'when it was given to someone else' do
      let(:member) { create(:member) }

      it { is_expected.to be false }
    end

    context 'with a garden that is not theirs' do
      let(:garden) { create(:garden) }

      it { is_expected.to be false }
    end

    context 'when already claimed' do
      before { gift.claim(member, garden) }

      it { is_expected.to be false }
    end
  end

  describe 'when only on offer' do
    subject(:offer) { create(:stall_planting, recipient_kind: nil, recipient: nil, given_away_at: nil) }

    it { is_expected.to be_valid }

    it { is_expected.not_to be_given }

    it 'leaves the planting active' do
      expect(Planting.active).to include(offer.planting)
    end

    it 'is not waiting for anyone' do
      expect(described_class.waiting_for(create(:member, email: 'neighbour@example.com'))).to be_empty
    end

    context 'when given to someone' do
      before { offer.update!(recipient_kind: 'email', recipient: 'neighbour@example.com', given_away_at: Time.zone.now) }

      it 'takes the planting off the active ones' do
        expect(Planting.active).not_to include(offer.planting)
      end
    end

    context 'when given without saying who' do
      it 'is not valid' do
        offer.given_away_at = Time.zone.now
        expect(offer).not_to be_valid
      end
    end
  end

  describe 'when its planting is on a second record' do
    let(:planting) { create(:stall_planting).planting }

    it 'is not valid while the first is unclaimed' do
      expect(build(:stall_planting, stall: planting.owner.stall, planting:)).not_to be_valid
    end
  end
end
