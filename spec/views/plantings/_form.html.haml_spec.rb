require 'spec_helper'

describe "plantings/_form" do
  before(:each) do
    controller.stub(:current_user) { Member.new }
    @member = FactoryGirl.create(:member)
    @garden = FactoryGirl.create(:garden, :owner => @member)
    @uppercase = FactoryGirl.create(:uppercasecrop)
    @lowercase = FactoryGirl.create(:lowercasecrop)
    @crop = @lowercase # needed to render the form

    @planting = FactoryGirl.create(:planting,
      :garden => @garden,
      :crop => @crop
    )
    render
  end

  context "logged in" do
    it "orders crops alphabetically" do
      rendered.should =~ /#{@lowercase.system_name}.*#{@uppercase.system_name}/m
    end
  end
end

