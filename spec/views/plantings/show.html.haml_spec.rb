require 'spec_helper'

describe "plantings/show" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    @garden = FactoryGirl.create(:garden, :owner => @member)
    @crop = FactoryGirl.create(:tomato)
    @planting = assign(:planting,
      FactoryGirl.create(:planting, :garden => @garden, :crop => @crop)
    )
    render
  end

  it "renders the quantity planted" do
    rendered.should match(/3/)
  end

  it "renders the description" do
    rendered.should match(/This is a/)
  end

  it "renders markdown in the description" do
    assert_select "em", "really"
  end
end
