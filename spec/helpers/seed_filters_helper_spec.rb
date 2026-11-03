# frozen_string_literal: true

require 'rails_helper'

describe SeedFiltersHelper do
  describe '#seed_view_path' do
    before do
      allow(helper.request).to receive_messages(path: '/seeds', query_parameters: { 'from' => 'bought', 'page' => '3', 'utm' => 'x' })
    end

    it { expect(helper.seed_view_path).to eq '/seeds?from=bought' }
    it { expect(helper.seed_view_path(heirloom: 'heirloom')).to eq '/seeds?from=bought&heirloom=heirloom' }
    it { expect(helper.seed_view_path(from: nil)).to eq '/seeds' }
    it { expect(helper.seed_view_path(path: '/members/x/seeds')).to eq '/members/x/seeds?from=bought' }
  end

  describe '#seed_heirloom_chips' do
    let(:chips) { helper.seed_heirloom_chips }

    it { expect(chips.map(&:first)).to eq ['Either', 'Heirloom only', 'Hybrid only'] }
    it { expect(chips.assoc('Hybrid only').last).to eq(heirloom: 'hybrid') }
  end

  describe '#seed_friend_names' do
    let(:viewer) { create(:member) }

    before do
      allow(helper).to receive(:current_member).and_return(viewer)
      create(:follow, follower: viewer, followed: create(:member, login_name: 'Zed'))
      create(:follow, follower: viewer, followed: create(:member, login_name: 'Amy'))
    end

    it { expect(helper.seed_friend_names).to eq %w(Amy Zed) }
  end

  describe '#seed_source_chips' do
    let(:chips) { helper.seed_source_chips }

    it { expect(chips.map(&:first)).to eq ['All', 'My own saving', 'Seed catalogue', 'Retail outlet', 'Seed bank', 'Traded from a person'] }
    it { expect(chips.first.last).to eq(from: nil) }
    it { expect(chips.assoc('Seed catalogue').last).to eq(from: 'catalogue') }
  end

  describe '#seed_filter_groups' do
    before { allow(helper).to receive(:current_member).and_return(viewer) }

    let(:viewer) { create(:london_member) }
    let(:groups) { helper.seed_filter_groups(everyone:) }

    context 'with the member\'s own seeds' do
      let(:everyone) { false }

      it { expect(groups.pluck(:label)).to eq ['Source', 'Sharing', 'Heirloom or hybrid', 'Planted'] }
    end

    context 'with everyone\'s seeds' do
      let(:everyone) { true }

      it { expect(groups.pluck(:label)).to eq ['Source', 'Distance', 'Heirloom or hybrid', 'Planted'] }
      it { expect(groups.second[:chips].pluck(:label)).to eq ['Anywhere', 'Within 50 km', 'Within 10 km'] }
    end

    context 'with everyone\'s seeds when signed out' do
      let(:everyone) { true }
      let(:viewer) { nil }

      it { expect(groups.pluck(:label)).to eq ['Source', 'Heirloom or hybrid', 'Planted'] }
    end
  end
end
