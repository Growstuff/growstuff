require 'rails_helper'

describe Garden do
  let(:owner) { FactoryBot.create(:member) }
  let(:garden) { FactoryBot.create(:garden, owner: owner) }

  it "should have a slug" do
    garden.slug.should match(/member\d+-springfield-community-garden/)
  end

  it "should have a description" do
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
    garden.should_not be_valid
  end

  it "allows brackets" do
    garden = FactoryBot.build(:garden, name: "Garden (second)")
    garden.should be_valid
  end

  it "allows macrons" do
    garden = FactoryBot.build(:garden, name: "Kūmara and pūha patch")
    garden.should_not be_valid
  end

  it "doesn't allow a name with only spaces" do
    garden = FactoryBot.build(:garden, name: "    ")
    garden.should_not be_valid
  end

  it "doesn't allow a new lines in garden names" do
    garden = FactoryBot.build(:garden, name: "My garden\nI am a 1337 hacker")
    garden.should_not be_valid
  end

  it "should have an owner" do
    garden.owner.should be_an_instance_of Member
  end

  it "should stringify as its name" do
    garden.to_s.should == garden.name
  end

  context "featured plantings" do
    let(:tomato) { FactoryBot.create(:tomato) }
    let(:maize) { FactoryBot.create(:maize) }
    let(:chard) { FactoryBot.create(:chard) }
    let(:apple) { FactoryBot.create(:apple) }
    let(:pear)  { FactoryBot.create(:pear) }
    let(:walnut) { FactoryBot.create(:walnut) }

    it "should fetch < 4 featured plantings if insufficient exist" do
      @p1 = FactoryBot.create(:planting, crop: tomato, garden: garden, owner: garden.owner)
      @p2 = FactoryBot.create(:planting, crop: maize, garden: garden, owner: garden.owner)

      garden.featured_plantings.should eq [@p2, @p1]
    end

    it "should fetch most recent 4 featured plantings" do
      @p1 = FactoryBot.create(:planting, crop: tomato, garden: garden, owner: garden.owner)
      @p2 = FactoryBot.create(:planting, crop: maize, garden: garden, owner: garden.owner)
      @p3 = FactoryBot.create(:planting, crop: chard, garden: garden, owner: garden.owner)
      @p4 = FactoryBot.create(:planting, crop: apple, garden: garden, owner: garden.owner)
      @p5 = FactoryBot.create(:planting, crop: walnut, garden: garden, owner: garden.owner)

      garden.featured_plantings.should eq [@p5, @p4, @p3, @p2]
    end

    it "should skip repeated plantings" do
      @p1 = FactoryBot.create(:planting, crop: tomato, garden: garden, owner: garden.owner)
      @p2 = FactoryBot.create(:planting, crop: maize, garden: garden, owner: garden.owner)
      @p3 = FactoryBot.create(:planting, crop: chard, garden: garden, owner: garden.owner)
      @p4 = FactoryBot.create(:planting, crop: apple, garden: garden, owner: garden.owner)
      @p5 = FactoryBot.create(:planting, crop: walnut, garden: garden, owner: garden.owner)
      @p6 = FactoryBot.create(:planting, crop: apple, garden: garden, owner: garden.owner)
      @p7 = FactoryBot.create(:planting, crop: pear, garden: garden, owner: garden.owner)

      garden.featured_plantings.should eq [@p7, @p6, @p5, @p3]
    end
  end

  it "destroys plantings when deleted" do
    garden = FactoryBot.create(:garden, owner: owner)
    @planting1 = FactoryBot.create(:planting, garden: garden, owner: garden.owner)
    @planting2 = FactoryBot.create(:planting, garden: garden, owner: garden.owner)
    garden.plantings.size.should eq(2)
    all = Planting.count
    garden.destroy
    Planting.count.should eq(all - 2)
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

    it 'should refuse invalid unit values' do
      garden = FactoryBot.build(:garden, area_unit: 'not valid')
      garden.should_not be_valid
      garden.errors[:area_unit].should include("not valid is not a valid area unit")
    end

    it 'sets area unit to blank if area is blank' do
      garden = FactoryBot.build(:garden, area: '', area_unit: 'acre')
      garden.should be_valid
      garden.area_unit.should eq nil
    end
  end

  context 'active scopes' do
    let(:active) { FactoryBot.create(:garden) }
    let(:inactive) { FactoryBot.create(:inactive_garden) }

    it 'includes active garden in active scope' do
      Garden.active.should include active
      Garden.active.should_not include inactive
    end
    it 'includes inactive garden in inactive scope' do
      Garden.inactive.should include inactive
      Garden.inactive.should_not include active
    end
  end

  it "marks plantings as finished when garden is inactive" do
    garden = FactoryBot.create(:garden)
    p1 = FactoryBot.create(:planting, garden: garden, owner: garden.owner)
    p2 = FactoryBot.create(:planting, garden: garden, owner: garden.owner)

    p1.finished.should eq false
    p2.finished.should eq false

    garden.active = false
    garden.save

    p1.reload
    p1.finished.should eq true
    p2.reload
    p2.finished.should eq true
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
    p1.finished.should eq true

    # plantings in other gardens should not be.
    p2.reload
    p2.finished.should eq false
  end

  context 'photos' do
    let(:garden) { FactoryBot.create(:garden) }
    let(:photo) { FactoryBot.create(:photo) }

    before do
      garden.photos << photo
    end

    it 'has a photo' do
      garden.photos.first.should eq photo
    end

    it 'deletes association with photos when photo is deleted' do
      photo.destroy
      garden.reload
      garden.photos.should be_empty
    end

    it 'has a default photo' do
      garden.default_photo.should eq photo
    end

    it 'chooses the most recent photo' do
      @photo2 = FactoryBot.create(:photo)
      garden.photos << @photo2
      garden.default_photo.should eq @photo2
    end
  end

  it 'excludes deleted members' do
    expect(Garden.joins(:owner).all).to include(garden)
    owner.destroy
    expect(Garden.joins(:owner).all).not_to include(garden)
  end
end
