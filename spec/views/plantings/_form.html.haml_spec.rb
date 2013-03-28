require 'spec_helper'

describe "plantings/_form" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @member = FactoryGirl.create(:member)
    @garden = FactoryGirl.create(:garden, :owner => @member)
    @uppercase = FactoryGirl.create(:uppercasecrop)
    @lowercase = FactoryGirl.create(:lowercasecrop)
    @crop = @lowercase # needed to render the form

    @planting = FactoryGirl.create(:planting,
      :garden => @garden,
      :crop => @crop,
      :planted_at => Date.new(2013, 03, 01)
    )
    render
  end

  it "has a free-form text field containing the planting date in ISO format" do
    assert_select 'input#planting_planted_at_string[type=text][value=2013-03-01]'
  end

  context "logged in" do
    it "orders crops alphabetically" do
      rendered.should =~ /#{@lowercase.system_name}.*#{@uppercase.system_name}/m
    end
  end
end

