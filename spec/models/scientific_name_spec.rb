require 'rails_helper'

describe ScientificName do
  context 'all fields present' do
    let(:sn) { FactoryBot.create(:zea_mays) }

    it 'should save a basic scientific name' do
      sn.save.should be(true)
    end

    it 'should be fetchable from the database' do
      sn.save
      @sn2 = ScientificName.find_by(name: 'Zea mays')
      @sn2.crop.name.should == 'maize'
    end

    it 'has a creator' do
      sn.save
      sn.creator.should be_an_instance_of Member
    end
  end

  context 'invalid data' do
    it 'should not save a scientific name without a name' do
      sn = ScientificName.new
      expect { sn.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end
end
