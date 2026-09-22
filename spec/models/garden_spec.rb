# frozen_string_literal: true

require 'rails_helper'

describe Garden do
  let(:owner)       { create(:member, login_name: 'hatupatu') }
  let(:garden)      { create(:garden, owner:, name: 'Springfield Community Garden') }

  it "has a slug" do
    garden.slug.should match(/hatupatu-springfield-community-garden/)
  end

  it "has a description" do
    garden.description.should == "This is a **totally** cool garden"
  end

  it "doesn't allow a nil name" do
    garden = build(:garden, name: nil)
    garden.should_not be_valid
  end

  it "doesn't allow a blank name" do
    garden = build(:garden, name: "")
    garden.should_not be_valid
  end

  it "allows numbers" do
    garden = build(:garden, name: "100 vines of 2 kamo-kamo")
    garden.should be_valid
  end

  it "allows brackets" do
    garden = build(:garden, name: "Garden (second)")
    garden.should be_valid
  end

  it "allows macrons" do
    garden = build(:garden, name: "Kūmara and pūha patch")
    garden.should be_valid
  end

  it "allows some punctuation" do
    garden = build(:garden, name: "best-garden-eva!")
    garden.should be_valid
  end

  it "doesn't allow a name with only spaces" do
    garden = build(:garden, name: "    ")
    garden.should_not be_valid
  end

  it "doesn't allow new line chars in garden names" do
    garden = build(:garden, name: "My garden\nI am a 1337 hacker")
    garden.should_not be_valid
  end

  it "has an owner" do
    garden.owner.should be_an_instance_of Member
  end

  it "stringifies as its name" do
    garden.to_s.should == garden.name
  end

  it "destroys plantings when deleted" do
    garden = create(:garden, owner:)
    @planting1 = create(:planting, garden:, owner: garden.owner)
    @planting2 = create(:planting, garden:, owner: garden.owner)
    expect(garden.plantings.size).to eq(2)
    all = Planting.count
    garden.destroy
    expect(Planting.count).to eq(all - 2)
  end

  context 'area' do
    it 'allows numeric area' do
      garden = build(:garden, area: 33)
      garden.should be_valid
    end

    it "doesn't allow negative area" do
      garden = build(:garden, area: -5)
      garden.should_not be_valid
    end

    it 'allows decimal quantities' do
      garden = build(:garden, area: 3.3)
      garden.should be_valid
    end

    it 'allows blank quantities' do
      garden = build(:garden, area: '')
      garden.should be_valid
    end

    it 'allows nil quantities' do
      garden = build(:garden, area: nil)
      garden.should be_valid
    end

    it 'cleans up zero quantities' do
      garden = build(:garden, area: 0)
      expect(garden.area).to eq 0
    end

    it "doesn't allow non-numeric quantities" do
      garden = build(:garden, area: "99a")
      garden.should_not be_valid
    end
  end

  context 'units' do
    Garden::AREA_UNITS_VALUES.values.push(nil, '').each do |s|
      it "#{s} should be a valid unit" do
        garden = build(:garden, area_unit: s)
        garden.should be_valid
      end
    end

    it 'refuses invalid unit values' do
      garden = build(:garden, area_unit: 'not valid')
      garden.should_not be_valid
      garden.errors[:area_unit].should include("not valid is not a valid area unit")
    end

    it 'sets area unit to blank if area is blank' do
      garden = build(:garden, area: '', area_unit: 'acre')
      garden.should be_valid
      expect(garden.area_unit).to be_nil
    end
  end

  context 'active scopes' do
    let(:active) { create(:garden) }
    let(:inactive) { create(:inactive_garden) }

    it 'includes active garden in active scope' do
      described_class.active.should include active
      described_class.active.should_not include inactive
    end

    it 'includes inactive garden in inactive scope' do
      described_class.inactive.should include inactive
      described_class.inactive.should_not include active
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
      garden.photos.should be_empty
    end

    it 'has a default photo' do
      expect(garden.default_photo).to eq photo
    end

    it 'chooses the most recent photo' do
      @photo2 = create(:photo, owner: garden.owner)
      garden.photos << @photo2
      expect(garden.default_photo).to eq @photo2
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
  end

  describe 'stepping stones, labels and rows' do
    let(:bed) { create(:garden, owner:, grid_columns: 4, grid_rows: 3) }

    def problems(features)
      bed.layout_feature_problems(features)
    end

    it 'takes stones, labels and rows that sit on the bed' do
      expect(problems([
                        { 'kind' => 'stone', 'x' => 0.4, 'y' => 2.6 },
                        { 'kind' => 'label', 'x' => 4, 'y' => 0, 'text' => 'path' },
                        { 'kind' => 'row', 'x' => 0.5, 'y' => 1, 'x2' => 3.5, 'y2' => 1, 'text' => '' }
                      ])).to be_empty
    end

    it 'refuses anything off the bed, including the far end of a row' do
      expect(problems([{ 'kind' => 'stone', 'x' => 4.5, 'y' => 1 }])).to eq ['A stone, label or row is off the bed']
      expect(problems([{ 'kind' => 'row', 'x' => 1, 'y' => 1, 'x2' => 9, 'y2' => 1 }])).to be_present
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
end
