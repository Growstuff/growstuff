require 'spec_helper'

describe "plantings/_thumbnail" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    @garden = FactoryGirl.create(:garden, :owner => @member)
    @crop = FactoryGirl.create(:tomato)

    @planting = FactoryGirl.create(:planting,
      :garden => @garden,
      :crop => @crop
    )

    render :partial => "thumbnail", :locals => {
      :planting => @planting,
      :show_crop => true,
      :show_location => true
    }
  end

  it "renders the quantity planted" do
    rendered.should contain "33"
  end

  it "renders the date planted" do
    rendered.should contain @planting.planted_at.to_s(:date)
  end

  it "shows the name of the crop" do
    rendered.should contain "Tomato"
  end

end
