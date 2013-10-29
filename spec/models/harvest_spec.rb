require 'spec_helper'

describe Harvest do

  it "has an owner" do
    harvest = FactoryGirl.create(:harvest)
    harvest.owner.should be_an_instance_of Member
  end

  it "has a crop" do
    harvest = FactoryGirl.create(:harvest)
    harvest.crop.should be_an_instance_of Crop
  end

  context 'quantity' do
    it 'allows numeric quantities' do
      @harvest = FactoryGirl.build(:harvest, :quantity => 33)
      @harvest.should be_valid
    end

    it 'allows decimal quantities' do
      @harvest = FactoryGirl.build(:harvest, :quantity => 3.3)
      @harvest.should be_valid
    end

    it 'allows blank quantities' do
      @harvest = FactoryGirl.build(:harvest, :quantity => '')
      @harvest.should be_valid
    end

    it 'allows nil quantities' do
      @harvest = FactoryGirl.build(:harvest, :quantity => nil)
      @harvest.should be_valid
    end

    it 'cleans up zero quantities' do
      @harvest = FactoryGirl.build(:harvest, :quantity => 0)
      @harvest.quantity.should == 0
    end

    it "doesn't allow non-numeric quantities" do
      @harvest = FactoryGirl.build(:harvest, :quantity => "99a")
      @harvest.should_not be_valid
    end
  end

  context 'units' do
    Harvest::UNITS_VALUES.values.push(nil, '').each do |s|
      it "#{s} should be a valid unit" do
        @harvest = FactoryGirl.build(:harvest, :unit => s)
        @harvest.should be_valid
      end
    end

    it 'should refuse invalid unit values' do
      @harvest = FactoryGirl.build(:harvest, :unit => 'not valid')
      @harvest.should_not be_valid
      @harvest.errors[:unit].should include("not valid is not a valid unit")
    end

    it 'sets unit to blank if quantity is blank' do
      @harvest = FactoryGirl.build(:harvest, :quantity => '', :unit => 'individual')
      @harvest.should be_valid
      @harvest.unit.should eq nil
    end
  end

  context 'weight quantity' do
    it 'allows numeric weight quantities' do
      @harvest = FactoryGirl.build(:harvest, :weight_quantity => 33)
      @harvest.should be_valid
    end

    it 'allows decimal weight quantities' do
      @harvest = FactoryGirl.build(:harvest, :weight_quantity => 3.3)
      @harvest.should be_valid
    end

    it 'allows blank weight quantities' do
      @harvest = FactoryGirl.build(:harvest, :weight_quantity => '')
      @harvest.should be_valid
    end

    it 'allows nil weight quantities' do
      @harvest = FactoryGirl.build(:harvest, :weight_quantity => nil)
      @harvest.should be_valid
    end

    it 'cleans up zero quantities' do
      @harvest = FactoryGirl.build(:harvest, :weight_quantity => 0)
      @harvest.weight_quantity.should == 0
    end

    it "doesn't allow non-numeric weight quantities" do
      @harvest = FactoryGirl.build(:harvest, :weight_quantity => "99a")
      @harvest.should_not be_valid
    end
  end

  context 'weight units' do
    it 'all valid units should work' do
      ['kg', 'lb', nil, ''].each do |s|
        @harvest = FactoryGirl.build(:harvest, :weight_unit => s)
        @harvest.should be_valid
      end
    end

    it 'should refuse invalid weight unit values' do
      @harvest = FactoryGirl.build(:harvest, :weight_unit => 'not valid')
      @harvest.should_not be_valid
      @harvest.errors[:weight_unit].should include("not valid is not a valid unit")
    end

    it 'sets weight_unit to blank if quantity is blank' do
      @harvest = FactoryGirl.build(:harvest, :weight_quantity => '', :weight_unit => 'kg')
      @harvest.should be_valid
      @harvest.weight_unit.should eq nil
    end
  end

  context "plant parts" do
    it 'all valid plant parts should work' do
      Harvest::PLANT_PARTS.push(nil, '').each do |p|
        @harvest = FactoryGirl.build(:harvest, :plant_part => p)
        @harvest.should be_valid
      end
    end

    it 'should refuse invalid plant parts' do
      @harvest = FactoryGirl.build(:harvest, :plant_part => 'leg')
      @harvest.should_not be_valid
      @harvest.errors[:plant_part].should include("leg is not a valid plant part")
    end
  end

end
