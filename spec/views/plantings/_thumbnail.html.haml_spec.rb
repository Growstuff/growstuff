require 'spec_helper'

describe "plantings/_thumbnail" do
  before(:each) do
    controller.stub(:current_user) { Member.new }
    @member = FactoryGirl.create(:member)
    @garden = FactoryGirl.create(:garden, :owner => @member)
    @crop = FactoryGirl.create(:tomato)

    @planting = FactoryGirl.create(:planting,
      :garden => @garden,
      :crop => @crop
    )
  end

  context "simple view" do
    before(:each) do
      render :partial => "thumbnail", :locals => {
        :planting => @planting,
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

    it "shows the description by default" do
      rendered.should contain "This is a"
    end
  end

  context "with complicated args" do
    before(:each) do
      render :partial => "thumbnail", :locals => {
        :planting => @planting,
        :hide_description => true
      }
    end

    it "hides the description if asked" do
      rendered.should_not contain "This is a"
    end
  end

end
