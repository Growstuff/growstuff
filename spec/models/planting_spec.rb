require 'spec_helper'

describe Planting do

  before(:each) do
    @crop = Crop.create(
      :system_name => "Tomato",
      :en_wikipedia_url => "http://en.wikipedia.org/wiki/Tomato"
    )

    @user = User.create!(
      :username => 'foo',
      :password => 'irrelevant',
      :email => 'foo@example.com',
      :tos_agreement => true
    )
    @user.confirm!

    @garden = Garden.create(
      :user_id => @user.id,
      :name => 'bar'
    )

    @planting = Planting.create(
      :garden_id => @garden.id,
      :crop_id => @crop.id
    )

  end

  it "generates an owner" do
    @planting.owner.should be_an_instance_of User
    @planting.owner.username.should match /^foo$/
  end

  it "generates a location" do
    @planting.location.should match /^foo's bar$/
  end

end
