# frozen_string_literal: true

require 'rails_helper'

describe Garden do
  let(:owner)       { create(:member, login_name: 'hatupatu') }
  let(:garden)      { create(:garden, owner:, name: 'Springfield Community Garden') }

  it "has a slug" do
    expect(garden.slug).to include('hatupatu-springfield-community-garden')
  end

  it "has a description" do
    expect(garden.description).to eq "This is a **totally** cool garden"
  end

  it "doesn't allow a nil name" do
    garden = build(:garden, name: nil)
    expect(garden).not_to be_valid
  end

  it "doesn't allow a blank name" do
    garden = build(:garden, name: "")
    expect(garden).not_to be_valid
  end

  it "allows numbers" do
    garden = build(:garden, name: "100 vines of 2 kamo-kamo")
    expect(garden).to be_valid
  end

  it "allows brackets" do
    garden = build(:garden, name: "Garden (second)")
    expect(garden).to be_valid
  end

  it "allows macrons" do
    garden = build(:garden, name: "Kūmara and pūha patch")
    expect(garden).to be_valid
  end

  it "allows some punctuation" do
    garden = build(:garden, name: "best-garden-eva!")
    expect(garden).to be_valid
  end

  it "doesn't allow a name with only spaces" do
    garden = build(:garden, name: "    ")
    expect(garden).not_to be_valid
  end

  it "doesn't allow new line chars in garden names" do
    garden = build(:garden, name: "My garden\nI am a 1337 hacker")
    expect(garden).not_to be_valid
  end

  it "has an owner" do
    expect(garden.owner).to be_an_instance_of Member
  end

  it "stringifies as its name" do
    expect(garden.to_s).to eq garden.name
  end

  it "destroys plantings when deleted" do
    garden = create(:garden, owner:)
    create(:planting, garden:, owner: garden.owner)
    create(:planting, garden:, owner: garden.owner)
    expect(garden.plantings.size).to eq(2)
    all = Planting.count
    garden.destroy
    expect(Planting.count).to eq(all - 2)
  end

  context 'area' do
    it 'allows numeric area' do
      garden = build(:garden, area: 33)
      expect(garden).to be_valid
    end

    it "doesn't allow negative area" do
      garden = build(:garden, area: -5)
      expect(garden).not_to be_valid
    end

    it 'allows decimal quantities' do
      garden = build(:garden, area: 3.3)
      expect(garden).to be_valid
    end

    it 'allows blank quantities' do
      garden = build(:garden, area: '')
      expect(garden).to be_valid
    end

    it 'allows nil quantities' do
      garden = build(:garden, area: nil)
      expect(garden).to be_valid
    end

    it 'cleans up zero quantities' do
      garden = build(:garden, area: 0)
      expect(garden.area).to eq 0
    end

    it "doesn't allow non-numeric quantities" do
      garden = build(:garden, area: "99a")
      expect(garden).not_to be_valid
    end
  end

  context 'units' do
    Garden::AREA_UNITS_VALUES.values.push(nil, '').each do |s|
      it "#{s} should be a valid unit" do
        garden = build(:garden, area_unit: s)
        expect(garden).to be_valid
      end
    end

    it 'refuses invalid unit values' do
      garden = build(:garden, area_unit: 'not valid')
      expect(garden).not_to be_valid
      expect(garden.errors[:area_unit]).to include("not valid is not a valid area unit")
    end

    it 'sets area unit to blank if area is blank' do
      garden = build(:garden, area: '', area_unit: 'acre')
      expect(garden).to be_valid
      expect(garden.area_unit).to be_nil
    end
  end

  context 'active scopes' do
    let(:active) { create(:garden) }
    let(:inactive) { create(:inactive_garden) }

    it 'includes active garden in active scope' do
      expect(described_class.active).to include active
      expect(described_class.active).not_to include inactive
    end

    it 'includes inactive garden in inactive scope' do
      expect(described_class.inactive).to include inactive
      expect(described_class.inactive).not_to include active
    end
  end

  it "marks plantings as finished when garden is inactive" do
    garden = create(:garden)
    p1 = create(:planting, garden:, owner: garden.owner)
    p2 = create(:planting, garden:, owner: garden.owner)

    expect(p1.finished).to be false
    expect(p2.finished).to be false

    garden.active = false
    garden.save

    p1.reload
    expect(p1.finished).to be true
    p2.reload
    expect(p2.finished).to be true
  end

  it "doesn't mark the wrong plantings as finished" do
    g1 = create(:garden)
    g2 = create(:garden)
    p1 = create(:planting, garden: g1, owner: g1.owner)
    p2 = create(:planting, garden: g2, owner: g2.owner)

    # mark the garden as inactive
    g1.active = false
    g1.save

    # plantings in that garden should be "finished"
    p1.reload
    expect(p1.finished).to be true

    # plantings in other gardens should not be.
    p2.reload
    expect(p2.finished).to be false
  end

  context 'photos' do
    let(:garden) { create(:garden) }
    let(:photo) { create(:photo, owner: garden.owner) }

    before do
      garden.photos << photo
    end

    it 'has a photo' do
      expect(garden.photos.first).to eq photo
    end

    it 'deletes association with photos when photo is deleted' do
      photo.destroy
      garden.reload
      expect(garden.photos).to be_empty
    end

    it 'has a default photo' do
      expect(garden.default_photo).to eq photo
    end

    it 'chooses the most recent photo' do
      photo2 = create(:photo, owner: garden.owner)
      garden.photos << photo2
      expect(garden.default_photo).to eq photo2
    end
  end

  context 'layout grid' do
    let(:bed) { create(:garden, owner:, name: 'Sunny bed', grid_columns: 4, grid_rows: 3) }

    it 'defaults to 10 by 10' do
      expect([garden.grid_columns, garden.grid_rows]).to eq [10, 10]
      expect(garden.grid_cells).to eq 100
    end

    it 'must have at least one cell, and no more than the cap' do
      expect(build(:garden, owner:, grid_columns: 0)).not_to be_valid
      expect(build(:garden, owner:, grid_rows: 0)).not_to be_valid
      expect(build(:garden, owner:, grid_columns: Garden::MAX_GRID_SIZE + 1)).not_to be_valid
      expect(build(:garden, owner:, grid_columns: Garden::MAX_GRID_SIZE)).to be_valid
    end

    it 'does not shrink out from under a placed plant' do
      planting = create(:planting, garden: bed, owner:, quantity: 1)
      bed.prepare_layout
      planting.plants.first.update!(bed_x: 3, bed_y: 2)
      bed.grid_columns = 2

      expect(bed).not_to be_valid
      expect(bed.errors[:base]).to be_present
    end

    it 'shrinks when nothing is in the way' do
      planting = create(:planting, garden: bed, owner:, quantity: 1)
      bed.prepare_layout
      planting.plants.first.update!(bed_x: 0, bed_y: 0)
      bed.grid_columns = 2

      expect(bed).to be_valid
    end

    it 'does not trigger geocoding when location has not changed' do
      expect(bed).not_to receive(:geocode)
      bed.update!(grid_columns: 6, grid_rows: 5)
    end
  end

  describe 'stepping stones, labels and rows' do
    let(:bed) { create(:garden, owner:, grid_columns: 4, grid_rows: 3) }

    def problems(features)
      bed.layout_feature_problems(features)
    end

    it 'takes stones, labels and rows that sit on the bed' do
      expect(problems([
                        { 'kind' => 'stone', 'x' => 0.4, 'y' => 2.6 },
                        { 'kind' => 'sprinkler', 'x' => 2, 'y' => 1.5 },
                        { 'kind' => 'tap', 'x' => 3.7, 'y' => 0.3 },
                        { 'kind' => 'stake', 'x' => 1, 'y' => 1 },
                        { 'kind' => 'path', 'x' => 0, 'y' => 2, 'x2' => 4, 'y2' => 2 },
                        { 'kind' => 'dripline', 'x' => 0.5, 'y' => 0.5, 'x2' => 0.5, 'y2' => 2.5 },
                        { 'kind' => 'fence', 'x' => 0, 'y' => 3, 'x2' => 4, 'y2' => 3 },
                        { 'kind' => 'trellis', 'x' => 3.5, 'y' => 0, 'x2' => 3.5, 'y2' => 3, 'text' => 'beans' },
                        { 'kind' => 'netting', 'x' => 0.5, 'y' => 0.5, 'x2' => 2.5, 'y2' => 2 },
                        { 'kind' => 'label', 'x' => 4, 'y' => 0, 'text' => 'path' },
                        { 'kind' => 'row', 'x' => 0.5, 'y' => 1, 'x2' => 3.5, 'y2' => 1, 'text' => '' }
                      ])).to be_empty
    end

    it 'refuses anything off the bed, including the far end of a row' do
      expect(problems([{ 'kind' => 'stone', 'x' => 4.5, 'y' => 1 }])).to eq ['A garden feature is off the bed']
      expect(problems([{ 'kind' => 'row', 'x' => 1, 'y' => 1, 'x2' => 9, 'y2' => 1 }])).to be_present
      expect(problems([{ 'kind' => 'sprinkler', 'x' => 1, 'y' => -1 }])).to be_present
      expect(problems([{ 'kind' => 'netting', 'x' => 1, 'y' => 1 }])).to be_present
    end

    it 'refuses things it does not know, empty labels and long names' do
      expect(problems([{ 'kind' => 'dragon', 'x' => 1, 'y' => 1 }])).to be_present
      expect(problems([{ 'kind' => 'label', 'x' => 1, 'y' => 1, 'text' => ' ' }])).to be_present
      expect(problems([{ 'kind' => 'label', 'x' => 1, 'y' => 1, 'text' => 'x' * 41 }])).to be_present
      expect(problems('not a list')).to be_present
    end

    it 'has a limit on how many there can be' do
      stones = Array.new(Garden::MAX_LAYOUT_FEATURES + 1) { { 'kind' => 'stone', 'x' => 1, 'y' => 1 } }
      expect(problems(stones)).to be_present
    end

    it 'is checked when the garden is saved' do
      bed.layout_features = [{ 'kind' => 'stone', 'x' => 10, 'y' => 1 }]
      expect(bed).not_to be_valid
    end

    it 'does not shrink the bed out from under one' do
      bed.update!(layout_features: [{ 'kind' => 'row', 'x' => 0.5, 'y' => 1, 'x2' => 3.5, 'y2' => 1 }])
      bed.grid_columns = 3

      expect(bed).not_to be_valid
    end
  end

  describe '#has_layout?' do
    let(:bed) { create(:garden, owner:) }

    it 'returns false when layout has not been used or saved' do
      expect(bed.has_layout?).to be false
    end

    it 'returns true when layout_saved_at is present' do
      bed.layout_saved_at = Time.current
      expect(bed.has_layout?).to be true
    end

    it 'returns true when layout_features are present' do
      bed.layout_features = [{ 'kind' => 'stone', 'x' => 1, 'y' => 1 }]
      expect(bed.has_layout?).to be true
    end

    it 'returns true when there are placed plants' do
      planting = create(:planting, garden: bed, owner:, quantity: 1)
      bed.prepare_layout
      planting.plants.first.update!(bed_x: 1, bed_y: 1)
      expect(bed.has_layout?).to be true
    end
  end

  describe '#prepare_layout' do
    let(:bed) { create(:garden, owner:) }

    it 'gives each planting growing here its plants' do
      two = create(:planting, garden: bed, owner:, quantity: 2)
      one = create(:planting, garden: bed, owner:, quantity: nil)
      bed.prepare_layout

      expect([two.plants.count, one.plants.count]).to eq [2, 1]
    end

    it 'leaves plantings that already have plants alone, so it can be run again' do
      planting = create(:planting, garden: bed, owner:, quantity: 2)
      bed.prepare_layout
      planting.plants.first.destroy

      expect { bed.prepare_layout }.not_to change(planting.plants, :count)
    end

    it "doesn't bring back a planting composted down to nothing" do
      planting = create(:planting, garden: bed, owner:, quantity: 0)

      expect { bed.prepare_layout }.not_to change(planting.plants, :count)
    end

    it 'skips plantings that are no longer growing, and other gardens' do
      finished = create(:planting, garden: bed, owner:, quantity: 2, finished: true, finished_at: 1.day.ago)
      elsewhere = create(:planting, quantity: 2)
      bed.prepare_layout

      expect(finished.plants).to be_empty
      expect(elsewhere.plants).to be_empty
    end
  end

  it 'excludes deleted members' do
    expect(described_class.joins(:owner).all).to include(garden)
    owner.destroy
    expect(described_class.joins(:owner).all).not_to include(garden)
  end

  describe 'nursery' do
    let(:owner) { create(:member) }

    before { create(:garden, owner:, nursery: true) }

    context 'when the owner already has one' do
      subject(:second) { build(:garden, owner:, nursery: true) }

      it { is_expected.not_to be_valid }
    end

    context 'when it is a different owner' do
      subject(:other) { build(:garden, nursery: true) }

      it { is_expected.to be_valid }
    end

    describe '#make_nursery!' do
      let(:garden) { create(:garden, owner:) }

      before { garden.make_nursery! }

      it('makes it the nursery') { expect(garden.reload).to be_nursery }
      it('replaces the old nursery') { expect(owner.gardens.nurseries).to contain_exactly(garden) }
    end

    it 'is left out of archiving' do
      owner.nursery!.update_column(:updated_at, 4.years.ago) # rubocop:disable Rails/SkipsModelValidations
      described_class.archive!
      expect(owner.nursery!.reload).to be_active
    end
  end
end
