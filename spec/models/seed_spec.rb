require 'spec_helper'

describe Seed do

  before(:each) do
    @seed = FactoryGirl.build(:seed)
  end

  it 'should save a basic seed' do
    @seed.save.should be_true
  end

end
