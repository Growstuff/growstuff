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
    it { expect(helper.seed_packet_sow_by(build(:seed, plant_before: 1.year.from_now.to_date))).to eq "sow by #{1.year.from_now.year}" }
    it { expect(helper.seed_packet_sow_by(build(:seed, plant_before: Date.new(2020, 12, 31)))).to eq 'past sow-by 2020' }
    it { expect(helper.seed_packet_sow_by(build(:seed, plant_before: nil))).to be_nil }
  end

  describe '#seed_stack_props' do
    subject(:props) { helper.seed_stack_props(seeds, show_owner:) }

    let(:crop) { create(:crop, name: 'Brandywine tomato') }
    let(:seeds) { create_list(:seed, 2, crop:, heirloom: 'heirloom') }
    let(:show_owner) { false }

    before do
      allow(helper).to receive_messages(can?: false, current_member: nil)
    end

    it { expect(props[:count]).to eq 2 }
    it { expect(props[:crop]).to eq(name: 'Brandywine tomato', path: crop_path(crop)) }
    it { expect(props[:heirloom]).to eq 'heirloom' }
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

    context 'with a packet past its sow-by year' do
      let(:seeds) { create_list(:seed, 2, crop:, plant_before: Date.new(2020, 12, 31)) }

      it { expect(props[:packets].first).to include(past: true, rule: 'past sow-by 2020') }
    end
  end

  describe 'distance from the signed-in member' do
    let(:viewer) { create(:london_member) }
    let(:near_seed) { create(:seed, owner: create(:london_member, login_name: 'near')) }
    let(:far_seed) { create(:seed, owner: create(:south_pole_member)) }
    let(:unlocated_seed) { create(:seed, owner: create(:member)) }

    context 'when signed in with a location' do
      before { allow(helper).to receive(:current_member).and_return(viewer) }

      it { expect(helper.seed_distance(far_seed)).to match(/\A\d+ km\z/) }
      it { expect(helper.seed_distance(unlocated_seed)).to be_nil }
      it { expect(helper.seed_owner_label(near_seed)).to match(/\Anear · Greenwich · \d+ km\z/) }
      it { expect(helper.seed_owner_label(unlocated_seed)).to eq unlocated_seed.owner.login_name }
    end

    context 'when signed out' do
      before { allow(helper).to receive(:current_member).and_return(nil) }

      it { expect(helper.seed_distance(near_seed)).to be_nil }
    end
  end

  describe '#seed_stacks' do
    let(:tomato) { create(:crop, name: 'tomato') }
    let(:cabbage) { create(:crop, name: 'cabbage') }
    let(:viewer) { create(:london_member) }
    let(:alex) { create(:south_pole_member) }
    let(:mere) { create(:london_member) }
    let!(:far_tomato) { create(:seed, owner: alex, crop: tomato) }
    let!(:second_far_tomato) { create(:seed, owner: alex, crop: tomato) }
    let!(:near_tomato) { create(:seed, owner: mere, crop: tomato) }
    let!(:cabbage_seed) { create(:seed, owner: alex, crop: cabbage) }
    let(:seeds) { [far_tomato, second_far_tomato, near_tomato, cabbage_seed] }

    before { allow(helper).to receive(:current_member).and_return(viewer) }

    context 'with one pile for each variety' do
      it { expect(helper.seed_stacks(seeds).map(&:size)).to eq [1, 3] }
      it { expect(helper.seed_stacks(seeds).first).to eq [cabbage_seed] }
    end

    context 'with one pile for each gardener and variety' do
      subject(:stacks) { helper.seed_stacks(seeds, by_owner: true) }

      it { expect(stacks.size).to eq 3 }
      it { expect(stacks.first).to eq [near_tomato] }
      it { expect(stacks.map(&:size)).to include(2) }
    end
  end

  describe '#seed_choice_link' do
    before { allow(helper).to receive(:url_for) { |**params| "/seeds?#{params.compact.to_query}" } }

    it { expect(helper.seed_choice_link('Crop', false, group: 'crop')).to have_link('Crop', href: '/seeds?group=crop', class: 'seed-chip') }
    it { expect(helper.seed_choice_link('Crop', true, group: 'crop')).to have_css('a.seed-chip.active') }
    it { expect(helper.seed_choice_link('List', true, css_class: nil, view: 'list')).to have_css('a.active:not(.seed-chip)') }
  end

  describe '#seed_filter_chips' do
    before { allow(helper).to receive(:current_member).and_return(viewer) }

    let(:viewer) { create(:london_member) }

    context 'with the member\'s own seeds' do
      let(:chips) { helper.seed_filter_chips(everyone: false) }
      let(:labels) { ['All', 'My own saving', 'Bought', 'Traded from a person', 'Heirloom only', 'Shared with others'] }

      it { expect(chips.map(&:first)).to eq labels }
      it { expect(chips.first.last).to be true }
    end

    context 'with everyone\'s seeds' do
      let(:chips) { helper.seed_filter_chips(everyone: true) }

      it { expect(chips.map(&:first)).to eq ['Anywhere', 'Within 50 km', 'Within 10 km', 'Heirloom only', 'Saved by the gardener'] }
    end

    context 'with everyone\'s seeds when signed out' do
      let(:viewer) { nil }
      let(:chips) { helper.seed_filter_chips(everyone: true) }

      it { expect(chips.map(&:first)).to eq ['Anywhere', 'Heirloom only', 'Saved by the gardener'] }
    end
  end
end
