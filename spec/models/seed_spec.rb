require 'spec_helper'

describe Seed do

  before(:each) do
    @seed = FactoryGirl.build(:seed)
  end

  it 'should save a basic seed' do
    @seed.save.should be_true
  end

  context 'tradable' do
    it 'all three valid tradable_to values should work' do
      ['locally', 'nationally', 'internationally', nil, ''].each do |t|
        @seed = FactoryGirl.build(:seed, :tradable_to => t)
        @seed.should be_valid
      end
    end

    it 'should refuse invalid tradable_to values' do
      @seed = FactoryGirl.build(:seed, :tradable_to => 'not valid')
      @seed.should_not be_valid
      @seed.errors[:tradable_to].should include("You may only trade seed locally, nationally, or internationally")
    end
  end
end
