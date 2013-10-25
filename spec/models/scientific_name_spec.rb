require 'spec_helper'

describe ScientificName do
  context 'all fields present' do

    before(:each) do
      @sn = FactoryGirl.create(:zea_mays)
    end

    it 'should save a basic scientific name' do
      @sn.save.should be_true
    end

    it 'should be fetchable from the database' do
      @sn.save
      @sn2 = ScientificName.find_by_scientific_name('Zea mays')
      @sn2.crop.name.should == "Maize"
    end

    it 'has a creator' do
      @sn.save
      @sn.creator.should be_an_instance_of Member
    end
  end

  context 'invalid data' do
    it 'should not save a scientific name without a name' do
      @sn = ScientificName.new
      expect { @sn.save }.to raise_error ActiveRecord::StatementInvalid
    end
  end
end
