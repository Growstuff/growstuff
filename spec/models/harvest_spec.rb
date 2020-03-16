# frozen_string_literal: true

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

    it 'refuses invalid unit values' do
      @harvest = FactoryBot.build(:harvest, unit: 'not valid')
      @harvest.should_not be_valid
      @harvest.errors[:unit].should include("not valid is not a valid unit")
    end

    it 'sets unit to blank if quantity is blank' do
      @harvest = FactoryBot.build(:harvest, quantity: '', unit: 'individual')
      @harvest.should be_valid
      expect(@harvest.unit).to eq nil
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

    it 'refuses invalid weight unit values' do
      @harvest = FactoryBot.build(:harvest, weight_unit: 'not valid')
      @harvest.should_not be_valid
      @harvest.errors[:weight_unit].should include("not valid is not a valid unit")
    end

    it 'sets weight_unit to blank if quantity is blank' do
      @harvest = FactoryBot.build(:harvest, weight_quantity: '', weight_unit: 'kg')
      @harvest.should be_valid
      expect(@harvest.weight_unit).to eq nil
    end
  end

  context "standardized weights" do
    it 'converts from pounds' do
      @harvest = FactoryBot.create(:harvest, weight_quantity: 2, weight_unit: "lb")
      @harvest.should be_valid
      expect(@harvest.reload.si_weight).to eq 0.907
    end

    it 'converts from ounces' do
      @harvest = FactoryBot.create(:harvest, weight_quantity: 16, weight_unit: "oz")
      @harvest.should be_valid
      expect(@harvest.reload.si_weight).to eq 0.454
    end

    it 'leaves kg alone' do
      @harvest = FactoryBot.create(:harvest, weight_quantity: 2, weight_unit: "kg")
      @harvest.should be_valid
      expect(@harvest.reload.si_weight).to eq 2.0
    end
  end

  context 'ordering' do
    it 'lists most recent harvests first' do
      @h1 = FactoryBot.create(:harvest, created_at: 1.day.ago)
      @h2 = FactoryBot.create(:harvest, created_at: 1.hour.ago)
      expect(described_class.all.order(created_at: :desc)).to eq [@h2, @h1]
    end
  end

  context "stringification" do
    let(:crop) { FactoryBot.create(:crop, name: "apricot") }

    it "apricots" do
      @h = FactoryBot.create(:harvest, crop:            crop,
                                       quantity:        nil,
                                       unit:            nil,
                                       weight_quantity: nil,
                                       weight_unit:     nil)
      expect(@h.to_s).to eq "apricots"
    end

    it "1 individual apricot" do
      @h = FactoryBot.create(:harvest, crop:            crop,
                                       quantity:        1,
                                       unit:            'individual',
                                       weight_quantity: nil,
                                       weight_unit:     nil)
      expect(@h.to_s).to eq "1 individual apricot"
    end

    it "10 individual apricots" do
      @h = FactoryBot.create(:harvest, crop:            crop,
                                       quantity:        10,
                                       unit:            'individual',
                                       weight_quantity: nil,
                                       weight_unit:     nil)
      expect(@h.to_s).to eq "10 individual apricots"
    end

    it "1 bushel of apricots" do
      @h = FactoryBot.create(:harvest, crop:            crop,
                                       quantity:        1,
                                       unit:            'bushel',
                                       weight_quantity: nil,
                                       weight_unit:     nil)
      expect(@h.to_s).to eq "1 bushel of apricots"
    end

    it "1.5 bushels of apricots" do
      @h = FactoryBot.create(:harvest, crop:            crop,
                                       quantity:        1.5,
                                       unit:            'bushel',
                                       weight_quantity: nil,
                                       weight_unit:     nil)
      expect(@h.to_s).to eq "1.5 bushels of apricots"
    end

    it "10 bushels of apricots" do
      @h = FactoryBot.create(:harvest, crop:            crop,
                                       quantity:        10,
                                       unit:            'bushel',
                                       weight_quantity: nil,
                                       weight_unit:     nil)
      expect(@h.to_s).to eq "10 bushels of apricots"
    end

    it "apricots weighing 1.2 kg" do
      @h = FactoryBot.create(:harvest, crop:            crop,
                                       quantity:        nil,
                                       unit:            nil,
                                       weight_quantity: 1.2,
                                       weight_unit:     'kg')
      expect(@h.to_s).to eq "apricots weighing 1.2 kg"
    end

    it "10 bushels of apricots weighing 100 kg" do
      @h = FactoryBot.create(:harvest, crop:            crop,
                                       quantity:        10,
                                       unit:            'bushel',
                                       weight_quantity: 100,
                                       weight_unit:     'kg')
      expect(@h.to_s).to eq "10 bushels of apricots weighing 100 kg"
    end
  end

  context 'photos' do
    before do
      @harvest = FactoryBot.create(:harvest)
    end

    context 'without a photo' do
      it 'has no default photo' do
        expect(@harvest.default_photo).to eq nil
      end

      context 'and with a crop(planting) photo' do
        before do
          @planting = FactoryBot.create(:planting, crop: @harvest.crop)
          @photo = FactoryBot.create(:photo, owner: @planting.owner)
          @planting.photos << @photo
          @harvest.update(planting: @planting)
        end

        it 'has a default photo' do
          expect(@harvest.default_photo).to eq @photo
        end
      end
    end

    context 'with a photo' do
      before do
        @photo = FactoryBot.create(:photo, owner: @harvest.owner)
        @harvest.photos << @photo
      end

      it 'is found in has_photos scope' do
        described_class.has_photos.should include(@harvest)
      end

      it 'has a photo' do
        expect(@harvest.photos.first).to eq @photo
      end

      it 'deletes association with photos when photo is deleted' do
        @photo.destroy
        @harvest.reload
        @harvest.photos.should be_empty
      end

      it 'has a default photo' do
        expect(@harvest.default_photo).to eq @photo
      end

      context 'and with a crop(planting) photo' do
        before do
          @planting = FactoryBot.create(:planting, crop: @harvest.crop)
          @crop_photo = FactoryBot.create(:photo, owner: @planting.owner)
          @planting.photos << @crop_photo
        end

        it 'prefers the harvest photo' do
          expect(@harvest.default_photo).to eq @photo
        end
      end

      context 'and a second photo' do
        before do
          @photo2 = FactoryBot.create(:photo, owner: @harvest.owner)
          @harvest.photos << @photo2
        end

        it 'chooses the most recent photo' do
          expect(@harvest.default_photo).to eq @photo2
        end
      end
    end
  end

  it 'excludes deleted members' do
    member = FactoryBot.create :member
    harvest = FactoryBot.create :harvest, owner: member
    expect(described_class.joins(:owner).all).to include(harvest)
    member.destroy
    expect(described_class.joins(:owner).all).not_to include(harvest)
  end
end
