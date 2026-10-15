# frozen_string_literal: true

require 'rails_helper'

describe SeedsHelper do
  describe "seed description" do
    it "is missing" do
      seed = create(:seed,
                    description: nil)
      result = helper.display_seed_description(seed)
      expect(result).to eq ""
    end

    it "is less than 130 characters long" do
      seed = create(:seed,
                    description: 'a' * 20)
      result = helper.display_seed_description(seed)
      expect(result).to eq 'a' * 20
    end

    it "is 130 characters long" do
      seed = create(:seed,
                    description: 'a' * 130)
      result = helper.display_seed_description(seed)
      expect(result).to eq 'a' * 130
    end

    it "is more than 130 characters long" do
      seed = create(:seed,
                    description: 'a' * 140)
      result = helper.display_seed_description(seed)
      expect(result).to eq ('a' * 126) + '...' + ' ' + link_to("Read more", seed_path(seed))
    end
  end

  describe '#seed_source_label' do
    it { expect(helper.seed_source_label('my own seed saving')).to eq 'own saving' }
    it { expect(helper.seed_source_label('seed bank or similar institution')).to eq 'seed bank' }
    it { expect(helper.seed_source_label('traded from another person')).to eq 'traded' }
    it { expect(helper.seed_source_label(nil)).to be_nil }
  end

  describe '#seed_packet_rule' do
    context 'with one packet saved on a date' do
      let(:seed) { build(:seed, saved_at: Date.new(2025, 3, 4), plant_before: Date.new(2027, 12, 31)) }

      it { expect(helper.seed_packet_rule([seed])).to eq 'saved 2025' }
    end

    context 'with one packet with only a sow-by year' do
      let(:seed) { build(:seed, saved_at: nil, plant_before: Date.new(2027, 12, 31)) }

      it { expect(helper.seed_packet_rule([seed])).to eq 'sow by 2027' }
    end

    context 'with a pile spanning years' do
      let(:seeds) { [build(:seed, saved_at: Date.new(2023, 1, 1)), build(:seed, saved_at: Date.new(2026, 1, 1))] }

      it { expect(helper.seed_packet_rule(seeds)).to eq '2023 – 2026' }
    end

    context 'with a pile all from one year' do
      let(:seeds) { [build(:seed, saved_at: Date.new(2024, 1, 1)), build(:seed, saved_at: Date.new(2024, 6, 1))] }

      it { expect(helper.seed_packet_rule(seeds)).to eq '2024' }
    end

    context 'with no dates at all' do
      let(:seed) { build(:seed, saved_at: nil, plant_before: nil) }

      it { expect(helper.seed_packet_rule([seed])).to be_nil }
    end
  end

  describe '#seed_packet_when' do
    it { expect(helper.seed_packet_when(build(:seed, saved_at: Date.new(2026, 10, 12)))).to eq 'saved 12 Oct 2026' }

    it 'words a traded packet by month' do
      seed = build(:seed, source: 'traded from another person', saved_at: Date.new(2023, 3, 9))
      expect(helper.seed_packet_when(seed)).to eq 'traded Mar 2023'
    end

    it 'falls back to where it came from' do
      expect(helper.seed_packet_when(build(:seed, saved_at: nil, source: 'retail outlet', created_at: Time.zone.now))).to eq 'retail outlet'
    end
  end

  describe '#seed_sharing' do
    it { expect(helper.seed_sharing(build(:seed, tradable_to: 'nowhere'))).to eq 'not shared' }
    it { expect(helper.seed_sharing(build(:seed, tradable_to: 'locally'))).to eq 'shared locally' }
  end

  describe '#seed_packet_sow_by' do
    let(:seed) { build(:seed, plant_before: Date.new(2027, 12, 31)) }

    it { expect(helper.seed_packet_sow_by(seed, false)).to eq 'sow by 2027' }
    it { expect(helper.seed_packet_sow_by(seed, true)).to eq 'past sow-by 2027' }
    it { expect(helper.seed_packet_sow_by(build(:seed, plant_before: nil), false)).to be_nil }
  end

  describe '#seed_stack_props' do
    subject(:props) { helper.seed_stack_props(seeds, open_crop_id: crop.id, show_owner: show_owner) }

    let(:crop) { create(:crop, name: 'Brandywine tomato') }
    let(:seeds) { create_list(:seed, 2, crop:, heirloom: 'heirloom') }
    let(:show_owner) { false }

    before { allow(helper).to receive(:can?).and_return(false) }

    it { expect(props[:count]).to eq 2 }
    it { expect(props[:crop]).to eq(name: 'Brandywine tomato', path: crop_path(crop)) }
    it { expect(props[:heirloom]).to eq 'heirloom' }
    it { expect(props[:open]).to be true }
    it { expect(props[:packets].size).to eq 2 }
    it { expect(props[:packets].first[:edit_path]).to be_nil }
    it { expect(props[:owner]).to be_nil }

    context 'when the member can edit' do
      before { allow(helper).to receive(:can?).with(:edit, anything).and_return(true) }

      it { expect(props[:packets].first[:edit_path]).to eq edit_seed_path(slug: seeds.first.slug) }
    end

    context 'when showing the owner' do
      let(:show_owner) { true }

      it { expect(props[:owner]).to include(name: seeds.first.owner.login_name, path: member_path(seeds.first.owner)) }
    end

    context 'when asked about a different crop' do
      subject(:props) { helper.seed_stack_props(seeds, open_crop_id: crop.id + 1) }

      it { expect(props[:open]).to be false }
    end
  end

  describe 'distance from the signed-in member' do
    let(:viewer) { create(:london_member) }
    let(:near_seed) { create(:seed, owner: create(:london_member)) }
    let(:far_seed) { create(:seed, owner: create(:south_pole_member)) }
    let(:unlocated_seed) { create(:seed, owner: create(:member)) }

    context 'when signed in with a location' do
      before { allow(helper).to receive(:current_member).and_return(viewer) }

      it { expect(helper.seed_distance(far_seed)).to match(/\A\d+ km\z/) }
      it { expect(helper.seed_distance(unlocated_seed)).to be_nil }
      it { expect(helper.nearest_first([far_seed, unlocated_seed, near_seed])).to eq [near_seed, far_seed, unlocated_seed] }
    end

    context 'when signed out' do
      before { allow(helper).to receive(:current_member).and_return(nil) }

      it { expect(helper.seed_distance(near_seed)).to be_nil }
      it { expect(helper.nearest_first([far_seed, near_seed])).to eq [far_seed, near_seed] }
    end
  end
end
