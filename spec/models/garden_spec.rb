# frozen_string_literal: true

require 'rails_helper'

describe Garden do
  let(:owner)       { create(:member, login_name: 'hatupatu') }
  let(:garden)      { create(:garden, owner:, name: 'Springfield Community Garden') }

  it "has a slug" do
    expect(garden.slug).to match(/hatupatu-springfield-community-garden/)
  end

  it "has a description" do
    expect(garden.description).to == "This is a **totally** cool garden"
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
    expect(garden.to_s).to == garden.name
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
      @photo2 = create(:photo, owner: garden.owner)
      garden.photos << @photo2
      expect(garden.default_photo).to eq @photo2
    end
  end

  it 'excludes deleted members' do
    expect(described_class.joins(:owner).all).to include(garden)
    owner.destroy
    expect(described_class.joins(:owner).all).not_to include(garden)
  end
end
