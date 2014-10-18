require 'spec_helper'

describe AlternateName do
  before (:each) do
    @an = FactoryGirl.create(:alternate_tomato)
  end

  it 'should save a basic alternate name' do
    @an.save.should be_true
  end
end
