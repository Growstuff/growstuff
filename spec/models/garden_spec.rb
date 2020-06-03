# frozen_string_literal: true

require 'rails_helper'

describe Garden do
  let(:owner)       { FactoryBot.create(:member, login_name: 'hatupatu')                             }
  let(:garden)      { FactoryBot.create(:garden, owner: owner, name: 'Springfield Community Garden') }

  it "has a slug" do
    garden.slug.should match(/hatupatu-springfield-community-garden/)
  end

  it "has a description" do
    garden.description.should == "This is a **totally** cool garden"
  end

  it "doesn't allow a nil name" do
    garden = FactoryBot.build(:garden, name: nil)
    garden.should_not be_valid
  end

  it "doesn't allow a blank name" do
    garden = FactoryBot.build(:garden, name: "")
    garden.should_not be_valid
  end

  it "allows numbers" do
    garden = FactoryBot.build(:garden, name: "100 vines of 2 kamo-kamo")
    garden.should be_valid
  end

  it "allows brackets" do
    garden = FactoryBot.build(:garden, name: "Garden (second)")
    garden.should be_valid
  end

  it "allows macrons" do
    garden = FactoryBot.build(:garden, name: "Kūmara and pūha patch")
    garden.should be_valid
  end

  it "allows some punctuation" do
    garden = FactoryBot.build(:garden, name: "best-garden-eva!")
    garden.should be_valid
  end

  it "doesn't allow a name with only spaces" do
    garden = FactoryBot.build(:garden, name: "    ")
    garden.should_not be_valid
  end

  it "doesn't allow new line chars in garden names" do
    garden = FactoryBot.build(:garden, name: "My garden\nI am a 1337 hacker")
    garden.should_not be_valid
  end

  it "has an owner" do
    garden.owner.should be_an_instance_of Member
  end

  it "stringifies as its name" do
    garden.to_s.should == garden.name
  end

  it "destroys plantings when deleted" do
    garden = FactoryBot.create(:garden, owner: owner)
    @planting1 = FactoryBot.create(:planting, garden: garden, owner: garden.owner)
    @planting2 = FactoryBot.create(:planting, garden: garden, owner: garden.owner)
    expect(garden.plantings.size).to eq(2)
    all = Planting.count
    garden.destroy
    expect(Planting.count).to eq(all - 2)
  end

  context 'area' do
    it 'allows numeric area' do
      garden = FactoryBot.build(:garden, area: 33)
      garden.should be_valid
    end

    it "doesn't allow negative area" do
      garden = FactoryBot.build(:garden, area: -5)
      garden.should_not be_valid
    end

    it 'allows decimal quantities' do
      garden = FactoryBot.build(:garden, area: 3.3)
      garden.should be_valid
    end

    it 'allows blank quantities' do
      garden = FactoryBot.build(:garden, area: '')
      garden.should be_valid
    end

    it 'allows nil quantities' do
      garden = FactoryBot.build(:garden, area: nil)
      garden.should be_valid
    end

    it 'cleans up zero quantities' do
      garden = FactoryBot.build(:garden, area: 0)
      garden.area.should == 0
    end

    it "doesn't allow non-numeric quantities" do
      garden = FactoryBot.build(:garden, area: "99a")
      garden.should_not be_valid
    end
  end

  context 'units' do
    Garden::AREA_UNITS_VALUES.values.push(nil, '').each do |s|
      it "#{s} should be a valid unit" do
        garden = FactoryBot.build(:garden, area_unit: s)
        garden.should be_valid
      end
    end

    it 'refuses invalid unit values' do
      garden = FactoryBot.build(:garden, area_unit: 'not valid')
      garden.should_not be_valid
      garden.errors[:area_unit].should include("not valid is not a valid area unit")
    end

    it 'sets area unit to blank if area is blank' do
      garden = FactoryBot.build(:garden, area: '', area_unit: 'acre')
      garden.should be_valid
      expect(garden.area_unit).to eq nil
    end
  end

  context 'active scopes' do
    let(:active) { FactoryBot.create(:garden) }
    let(:inactive) { FactoryBot.create(:inactive_garden) }

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
    garden = FactoryBot.create(:garden)
    p1 = FactoryBot.create(:planting, garden: garden, owner: garden.owner)
    p2 = FactoryBot.create(:planting, garden: garden, owner: garden.owner)

    expect(p1.finished).to eq false
    expect(p2.finished).to eq false

    garden.active = false
    garden.save

    p1.reload
    expect(p1.finished).to eq true
    p2.reload
    expect(p2.finished).to eq true
  end

  it "doesn't mark the wrong plantings as finished" do
    g1 = FactoryBot.create(:garden)
    g2 = FactoryBot.create(:garden)
    p1 = FactoryBot.create(:planting, garden: g1, owner: g1.owner)
    p2 = FactoryBot.create(:planting, garden: g2, owner: g2.owner)

    # mark the garden as inactive
    g1.active = false
    g1.save

    # plantings in that garden should be "finished"
    p1.reload
    expect(p1.finished).to eq true

    # plantings in other gardens should not be.
    p2.reload
    expect(p2.finished).to eq false
  end

  context 'photos' do
    let(:garden) { FactoryBot.create(:garden) }
    let(:photo) { FactoryBot.create(:photo, owner: garden.owner) }

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
      @photo2 = FactoryBot.create(:photo, owner: garden.owner)
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
