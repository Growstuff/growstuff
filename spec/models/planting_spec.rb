require 'spec_helper'

describe Planting do

  before(:each) do
    @crop     = FactoryGirl.create(:tomato)
    @user     = FactoryGirl.create(:user)
    @garden   = FactoryGirl.create(:garden, :user => @user)
    @planting = FactoryGirl.create(:planting,
        :crop => @crop, :garden => @garden)
  end

  it "generates an owner" do
    @planting.owner.should be_an_instance_of User
    @planting.owner.username.should match /^user1$/
  end

  it "generates a location" do
    @planting.location.should match /^user1's My Garden$/
  end

end
