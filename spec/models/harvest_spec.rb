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

end
