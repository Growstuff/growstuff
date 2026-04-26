# frozen_string_literal: true

require 'rails_helper'

describe Harvest do
  it "has an owner" do
    harvest = create(:harvest)
    expect(harvest.owner).to be_an_instance_of Member
  end

  it "has a crop" do
    harvest = create(:harvest)
    expect(harvest.crop).to be_an_instance_of Crop
  end

  context 'quantity' do
    it 'allows numeric quantities' do
      @harvest = build(:harvest, quantity: 33)
      expect(@harvest).to be_valid
    end

    it 'allows decimal quantities' do
      @harvest = build(:harvest, quantity: 3.3)
      expect(@harvest).to be_valid
    end

    it 'allows blank quantities' do
      @harvest = build(:harvest, quantity: '')
      expect(@harvest).to be_valid
    end

    it 'allows nil quantities' do
      @harvest = build(:harvest, quantity: nil)
      expect(@harvest).to be_valid
    end

    it 'cleans up zero quantities' do
      @harvest = build(:harvest, quantity: 0)
      expect(@harvest.quantity).to eq 0
    end

    it "doesn't allow non-numeric quantities" do
      @harvest = build(:harvest, quantity: "99a")
      expect(@harvest).not_to be_valid
    end
  end

  context 'units' do
    it 'all valid units should work' do
      ['individual', 'bunch', 'sprig', 'handful', 'litre',
       'pint', 'quart', 'bucket', 'basket', 'bushel', nil, ''].each do |s|
        @harvest = build(:harvest, unit: s)
        expect(@harvest).to be_valid
      end
    end

    it 'refuses invalid unit values' do
      @harvest = build(:harvest, unit: 'not valid')
      expect(@harvest).not_to be_valid
      expect(@harvest.errors[:unit]).to include("not valid is not a valid unit")
    end

    it 'sets unit to blank if quantity is blank' do
      @harvest = build(:harvest, quantity: '', unit: 'individual')
      expect(@harvest).to be_valid
      expect(@harvest.unit).to be_nil
    end
  end

  context 'weight quantity' do
    it 'allows numeric weight quantities' do
      @harvest = build(:harvest, weight_quantity: 33)
      expect(@harvest).to be_valid
    end

    it 'allows decimal weight quantities' do
      @harvest = build(:harvest, weight_quantity: 3.3)
      expect(@harvest).to be_valid
    end

    it 'allows blank weight quantities' do
      @harvest = build(:harvest, weight_quantity: '')
      expect(@harvest).to be_valid
    end

    it 'allows nil weight quantities' do
      @harvest = build(:harvest, weight_quantity: nil)
      expect(@harvest).to be_valid
    end

    it 'cleans up zero quantities' do
      @harvest = build(:harvest, weight_quantity: 0)
      expect(@harvest.weight_quantity).to eq 0
    end

    it "doesn't allow non-numeric weight quantities" do
      @harvest = build(:harvest, weight_quantity: "99a")
      expect(@harvest).not_to be_valid
    end
  end

  context 'weight units' do
    it 'all valid units should work' do
      ['kg', 'lb', 'oz', nil, ''].each do |s|
        @harvest = build(:harvest, weight_unit: s)
        expect(@harvest).to be_valid
      end
    end

    it 'refuses invalid weight unit values' do
      @harvest = build(:harvest, weight_unit: 'not valid')
      expect(@harvest).not_to be_valid
      expect(@harvest.errors[:weight_unit]).to include("not valid is not a valid unit")
    end

    it 'sets weight_unit to blank if quantity is blank' do
      @harvest = build(:harvest, weight_quantity: '', weight_unit: 'kg')
      expect(@harvest).to be_valid
      expect(@harvest.weight_unit).to be_nil
    end
  end

  context "standardized weights" do
    it 'converts from pounds' do
      @harvest = create(:harvest, weight_quantity: 2, weight_unit: "lb")
      expect(@harvest).to be_valid
      expect(@harvest.reload.si_weight).to eq 0.907
    end

    it 'converts from ounces' do
      @harvest = create(:harvest, weight_quantity: 16, weight_unit: "oz")
      expect(@harvest).to be_valid
      expect(@harvest.reload.si_weight).to eq 0.454
    end

    it 'leaves kg alone' do
      @harvest = create(:harvest, weight_quantity: 2, weight_unit: "kg")
      expect(@harvest).to be_valid
      expect(@harvest.reload.si_weight).to eq 2.0
    end
  end

  context 'ordering' do
    it 'lists most recent harvests first' do
      @h1 = create(:harvest, created_at: 1.day.ago)
      @h2 = create(:harvest, created_at: 1.hour.ago)
      expect(described_class.order(created_at: :desc)).to eq [@h2, @h1]
    end
  end

  context "stringification" do
    let(:crop) { create(:crop, name: "apricot") }

    it "apricots" do
      @h = create(:harvest, crop:,
                            quantity:        nil,
                            unit:            nil,
                            weight_quantity: nil,
                            weight_unit:     nil)
      expect(@h.to_s).to eq "apricots"
    end

    it "1 individual apricot" do
      @h = create(:harvest, crop:,
                            quantity:        1,
                            unit:            'individual',
                            weight_quantity: nil,
                            weight_unit:     nil)
      expect(@h.to_s).to eq "1 individual apricot"
    end

    it "10 individual apricots" do
      @h = create(:harvest, crop:,
                            quantity:        10,
                            unit:            'individual',
                            weight_quantity: nil,
                            weight_unit:     nil)
      expect(@h.to_s).to eq "10 individual apricots"
    end

    it "1 bushel of apricots" do
      @h = create(:harvest, crop:,
                            quantity:        1,
                            unit:            'bushel',
                            weight_quantity: nil,
                            weight_unit:     nil)
      expect(@h.to_s).to eq "1 bushel of apricots"
    end

    it "1.5 bushels of apricots" do
      @h = create(:harvest, crop:,
                            quantity:        1.5,
                            unit:            'bushel',
                            weight_quantity: nil,
                            weight_unit:     nil)
      expect(@h.to_s).to eq "1.5 bushels of apricots"
    end

    it "10 bushels of apricots" do
      @h = create(:harvest, crop:,
                            quantity:        10,
                            unit:            'bushel',
                            weight_quantity: nil,
                            weight_unit:     nil)
      expect(@h.to_s).to eq "10 bushels of apricots"
    end

    it "apricots weighing 1.2 kg" do
      @h = create(:harvest, crop:,
                            quantity:        nil,
                            unit:            nil,
                            weight_quantity: 1.2,
                            weight_unit:     'kg')
      expect(@h.to_s).to eq "apricots weighing 1.2 kg"
    end

    it "10 bushels of apricots weighing 100 kg" do
      @h = create(:harvest, crop:,
                            quantity:        10,
                            unit:            'bushel',
                            weight_quantity: 100,
                            weight_unit:     'kg')
      expect(@h.to_s).to eq "10 bushels of apricots weighing 100 kg"
    end
  end

  context 'photos' do
    before do
      @harvest = create(:harvest)
    end

    context 'without a photo' do
      it 'has no default photo' do
        expect(@harvest.default_photo).to be_nil
      end

      context 'and with a crop(planting) photo' do
        before do
          @planting = create(:planting, crop: @harvest.crop)
          @photo = create(:photo, owner: @planting.owner)
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
        @photo = create(:photo, owner: @harvest.owner)
        @harvest.photos << @photo
      end

      it 'is found in has_photos scope' do
        expect(described_class.has_photos).to include(@harvest)
      end

      it 'has a photo' do
        expect(@harvest.photos.first).to eq @photo
      end

      it 'deletes association with photos when photo is deleted' do
        @photo.destroy
        @harvest.reload
        expect(@harvest.photos).to be_empty
      end

      it 'has a default photo' do
        expect(@harvest.default_photo).to eq @photo
      end

      context 'and with a crop(planting) photo' do
        before do
          @planting = create(:planting, crop: @harvest.crop)
          @crop_photo = create(:photo, owner: @planting.owner)
          @planting.photos << @crop_photo
        end

        it 'prefers the harvest photo' do
          expect(@harvest.default_photo).to eq @photo
        end
      end

      context 'and a second photo' do
        before do
          @photo2 = create(:photo, owner: @harvest.owner)
          @harvest.photos << @photo2
        end

        it 'chooses the most recent photo' do
          expect(@harvest.default_photo).to eq @photo2
        end
      end
    end
  end

  it 'excludes deleted members' do
    member = create(:member)
    harvest = create(:harvest, owner: member)
    expect(described_class.joins(:owner).all).to include(harvest)
    member.destroy
    expect(described_class.joins(:owner).all).not_to include(harvest)
  end
end
