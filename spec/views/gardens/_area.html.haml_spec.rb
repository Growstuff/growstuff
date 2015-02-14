require 'rails_helper'

describe "gardens/_area" do

  it "check unit of measurement NO AREA" do
    garden = FactoryGirl.create(:garden_no_area)
    render(:partial => "gardens/area", locals: {:garden => garden})
    response.should == ''
  end

  it "check unit of measurement SQUARE METER" do
    garden = FactoryGirl.create(:garden_square_metre)
    render(:partial => "gardens/area", locals: {:garden => garden})
    response.should match(/m\n<sup>2<\/sup>/i)
  end

  it "check unit of measurement SQUARE FOOT" do
    garden = FactoryGirl.create(:garden_square_foot)
    render(:partial => "gardens/area", locals: {:garden => garden})
    response.should match(/ft\n<sup>2<\/sup>/i)
  end

  it "check unit of measurement HECTARE" do
    garden = FactoryGirl.create(:garden_hectare)
    render(:partial => "gardens/area", locals: {:garden => garden})
    response.should match(/HA/i)
  end

  it "check unit of measurement ACRE" do
    garden = FactoryGirl.create(:garden_acre)
    render(:partial => "gardens/area", locals: {:garden => garden})
    response.should match(/A/i)
  end

end