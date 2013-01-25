require 'spec_helper'

describe "plantings/_form" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    @garden = FactoryGirl.create(:garden, :owner => @member)
    @crop = FactoryGirl.create(:tomato)
    FactoryGirl.create(:lowercasecrop)

    @planting = FactoryGirl.create(:planting,
      :garden => @garden,
      :crop => @crop
    )
    render
  end

  context "logged in" do
    it "orders crops alphabetically" do
      rendered.should =~ /ffrench bean.*Tomato/m
    end
  end
end

