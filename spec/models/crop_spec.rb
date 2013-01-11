require 'spec_helper'

describe Crop do
  context 'all fields present' do

    before(:each) do
      @crop = FactoryGirl.create(:tomato)
    end

    it 'should save a basic crop' do
      @crop.save.should be_true
    end

    it 'should be fetchable from the database' do
      @crop.save
      @crop2 = Crop.find_by_system_name('Tomato')
      @crop2.en_wikipedia_url.should == "http://en.wikipedia.org/wiki/Tomato"
      @crop2.slug.should == "tomato"
    end

    it 'should stringify as the system name' do
      @crop.save
      @crop.to_s.should == 'Tomato'
      "#{@crop}".should == 'Tomato'
    end
  end

  context 'invalid data' do
    it 'should not save a crop without a system name' do
      @crop = Crop.new
      expect { @crop.save }.to raise_error ActiveRecord::StatementInvalid
    end
  end

  context 'random' do
    before(:each) do
      @crop = FactoryGirl.create(:tomato)
    end

    it 'should find a random crop' do
      @rand_crop = Crop.random
      @rand_crop.system_name.should == 'Tomato'
    end
  end
end
