require 'rails_helper'

describe Harvest do
  it "has an owner" do
    harvest = FactoryBot.create(:harvest)
    harvest.owner.should be_an_instance_of Member
  end

  it "has a crop" do
    harvest = FactoryBot.create(:harvest)
    harvest.crop.should be_an_instance_of Crop
  end

  context 'quantity' do
    it 'allows numeric quantities' do
      @harvest = FactoryBot.build(:harvest, quantity: 33)
      @harvest.should be_valid
    end

    it 'allows decimal quantities' do
      @harvest = FactoryBot.build(:harvest, quantity: 3.3)
      @harvest.should be_valid
    end

    it 'allows blank quantities' do
      @harvest = FactoryBot.build(:harvest, quantity: '')
      @harvest.should be_valid
    end

    it 'allows nil quantities' do
      @harvest = FactoryBot.build(:harvest, quantity: nil)
      @harvest.should be_valid
    end

    it 'cleans up zero quantities' do
      @harvest = FactoryBot.build(:harvest, quantity: 0)
      @harvest.quantity.should == 0
    end

    it "doesn't allow non-numeric quantities" do
      @harvest = FactoryBot.build(:harvest, quantity: "99a")
      @harvest.should_not be_valid
    end
  end

  context 'units' do
    it 'all valid units should work' do
      ['individual', 'bunch', 'sprig', 'handful', 'litre',
       'pint', 'quart', 'bucket', 'basket', 'bushel', nil, ''].each do |s|
        @harvest = FactoryBot.build(:harvest, unit: s)
        @harvest.should be_valid
      end
    end

    it 'should refuse invalid unit values' do
      @harvest = FactoryBot.build(:harvest, unit: 'not valid')
      @harvest.should_not be_valid
      @harvest.errors[:unit].should include("not valid is not a valid unit")
    end

    it 'sets unit to blank if quantity is blank' do
      @harvest = FactoryBot.build(:harvest, quantity: '', unit: 'individual')
      @harvest.should be_valid
      @harvest.unit.should eq nil
    end
  end

  context 'weight quantity' do
    it 'allows numeric weight quantities' do
      @harvest = FactoryBot.build(:harvest, weight_quantity: 33)
      @harvest.should be_valid
    end

    it 'allows decimal weight quantities' do
      @harvest = FactoryBot.build(:harvest, weight_quantity: 3.3)
      @harvest.should be_valid
    end

    it 'allows blank weight quantities' do
      @harvest = FactoryBot.build(:harvest, weight_quantity: '')
      @harvest.should be_valid
    end

    it 'allows nil weight quantities' do
      @harvest = FactoryBot.build(:harvest, weight_quantity: nil)
      @harvest.should be_valid
    end

    it 'cleans up zero quantities' do
      @harvest = FactoryBot.build(:harvest, weight_quantity: 0)
      @harvest.weight_quantity.should == 0
    end

    it "doesn't allow non-numeric weight quantities" do
      @harvest = FactoryBot.build(:harvest, weight_quantity: "99a")
      @harvest.should_not be_valid
    end
  end

  context 'weight units' do
    it 'all valid units should work' do
      ['kg', 'lb', 'oz', nil, ''].each do |s|
        @harvest = FactoryBot.build(:harvest, weight_unit: s)
        @harvest.should be_valid
      end
    end

    it 'should refuse invalid weight unit values' do
      @harvest = FactoryBot.build(:harvest, weight_unit: 'not valid')
      @harvest.should_not be_valid
      @harvest.errors[:weight_unit].should include("not valid is not a valid unit")
    end

    it 'sets weight_unit to blank if quantity is blank' do
      @harvest = FactoryBot.build(:harvest, weight_quantity: '', weight_unit: 'kg')
      @harvest.should be_valid
      @harvest.weight_unit.should eq nil
    end
  end

  context "standardized weights" do
    it 'converts from pounds' do
      @harvest = FactoryBot.create(:harvest, weight_quantity: 2, weight_unit: "lb")
      @harvest.should be_valid
      @harvest.reload.si_weight.should eq 0.907
    end

    it 'converts from ounces' do
      @harvest = FactoryBot.create(:harvest, weight_quantity: 16, weight_unit: "oz")
      @harvest.should be_valid
      @harvest.reload.si_weight.should eq 0.454
    end

    it 'leaves kg alone' do
      @harvest = FactoryBot.create(:harvest, weight_quantity: 2, weight_unit: "kg")
      @harvest.should be_valid
      @harvest.reload.si_weight.should eq 2.0
    end
  end

  context 'ordering' do
    it 'lists most recent harvests first' do
      @h1 = FactoryBot.create(:harvest, created_at: 1.day.ago)
      @h2 = FactoryBot.create(:harvest, created_at: 1.hour.ago)
      Harvest.all.order(created_at: :desc).should eq [@h2, @h1]
    end
  end

  context "stringification" do
    let(:crop) { FactoryBot.create(:crop, name: "apricot") }

    it "apricots" do
      @h = FactoryBot.create(:harvest, crop: crop,
                                       quantity: nil,
                                       unit: nil,
                                       weight_quantity: nil,
                                       weight_unit: nil)
      @h.to_s.should eq "apricots"
    end

    it "1 individual apricot" do
      @h = FactoryBot.create(:harvest, crop: crop,
                                       quantity: 1,
                                       unit: 'individual',
                                       weight_quantity: nil,
                                       weight_unit: nil)
      @h.to_s.should eq "1 individual apricot"
    end

    it "10 individual apricots" do
      @h = FactoryBot.create(:harvest, crop: crop,
                                       quantity: 10,
                                       unit: 'individual',
                                       weight_quantity: nil,
                                       weight_unit: nil)
      @h.to_s.should eq "10 individual apricots"
    end

    it "1 bushel of apricots" do
      @h = FactoryBot.create(:harvest, crop: crop,
                                       quantity: 1,
                                       unit: 'bushel',
                                       weight_quantity: nil,
                                       weight_unit: nil)
      @h.to_s.should eq "1 bushel of apricots"
    end

    it "1.5 bushels of apricots" do
      @h = FactoryBot.create(:harvest, crop: crop,
                                       quantity: 1.5,
                                       unit: 'bushel',
                                       weight_quantity: nil,
                                       weight_unit: nil)
      @h.to_s.should eq "1.5 bushels of apricots"
    end

    it "10 bushels of apricots" do
      @h = FactoryBot.create(:harvest, crop: crop,
                                       quantity: 10,
                                       unit: 'bushel',
                                       weight_quantity: nil,
                                       weight_unit: nil)
      @h.to_s.should eq "10 bushels of apricots"
    end

    it "apricots weighing 1.2 kg" do
      @h = FactoryBot.create(:harvest, crop: crop,
                                       quantity: nil,
                                       unit: nil,
                                       weight_quantity: 1.2,
                                       weight_unit: 'kg')
      @h.to_s.should eq "apricots weighing 1.2 kg"
    end

    it "10 bushels of apricots weighing 100 kg" do
      @h = FactoryBot.create(:harvest, crop: crop,
                                       quantity: 10,
                                       unit: 'bushel',
                                       weight_quantity: 100,
                                       weight_unit: 'kg')
      @h.to_s.should eq "10 bushels of apricots weighing 100 kg"
    end
  end

  context 'photos' do
    before :each do
      @harvest = FactoryBot.create(:harvest)
    end

    context 'without a photo' do
      it 'should have no default photo' do
        @harvest.default_photo.should eq nil
      end

      context 'and with a crop(planting) photo' do
        before :each do
          @photo = FactoryBot.create(:photo)
          @planting = FactoryBot.create(:planting, crop: @harvest.crop)
          @planting.photos << @photo
        end

        it 'should have a default photo' do
          @harvest.default_photo.should eq @photo
        end
      end
    end

    context 'with a photo' do
      before do
        @photo = FactoryBot.create(:photo)

        @harvest.photos << @photo
      end

      it 'is found in has_photos scope' do
        Harvest.has_photos.should include(@harvest)
      end

      it 'has a photo' do
        @harvest.photos.first.should eq @photo
      end

      it 'deletes association with photos when photo is deleted' do
        @photo.destroy
        @harvest.reload
        @harvest.photos.should be_empty
      end

      it 'has a default photo' do
        @harvest.default_photo.should eq @photo
      end

      context 'and with a crop(planting) photo' do
        before :each do
          @crop_photo = FactoryBot.create(:photo)
          @planting = FactoryBot.create(:planting, crop: @harvest.crop)
          @planting.photos << @crop_photo
        end

        it 'should prefer the harvest photo' do
          @harvest.default_photo.should eq @photo
        end
      end

      context 'and a second photo' do
        before :each do
          @photo2 = FactoryBot.create(:photo)
          @harvest.photos << @photo2
        end

        it 'chooses the most recent photo' do
          @harvest.default_photo.should eq @photo2
        end
      end
    end
  end

  it 'excludes deleted members' do
    member = FactoryBot.create :member
    harvest = FactoryBot.create :harvest, owner: member
    expect(Harvest.joins(:owner).all).to include(harvest)
    member.destroy
    expect(Harvest.joins(:owner).all).not_to include(harvest)
  end
end
