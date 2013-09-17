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

    it "doesn't allow non-numeric quantities" do
      @harvest = FactoryGirl.build(:harvest, :quantity => "99a")
      @harvest.should_not be_valid
    end
  end

  context 'units' do
    it 'all valid units should work' do
      ['individual', 'bunches', 'kg', 'lb', nil, ''].each do |s|
        @harvest = FactoryGirl.build(:harvest, :unit=> s)
        @harvest.should be_valid
      end
    end

    it 'should refuse invalid unit values' do
      @harvest = FactoryGirl.build(:harvest, :unit => 'not valid')
      @harvest.should_not be_valid
      @harvest.errors[:unit].should include("not valid is not a valid unit")
    end

    it 'sets unit to blank if quantity is blank' do
      @harvest = FactoryGirl.build(:harvest, :quantity => '', :unit => 'kg')
      @harvest.should be_valid
      @harvest.unit.should eq nil
    end
  end



end
