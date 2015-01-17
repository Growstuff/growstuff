require 'rails_helper'

describe "crops/_planting_advice" do
  before(:each) do
    @owner    = FactoryGirl.create(:member)
    @crop = FactoryGirl.create(:crop)
    @garden   = FactoryGirl.create(:garden, :owner => @owner)
    @planting = FactoryGirl.create(:planting,
      :garden => @garden,
      :crop => @crop
    )
  end

  context "sunniness" do
    it "doesn't show sunniness if none are set" do
      render :partial => 'crops/planting_advice', :locals => { :crop => @crop }
      rendered.should have_content "Plant in: not known."
    end

    it "shows sunniness frequencies" do
      FactoryGirl.create(:sunny_planting, :crop => @crop)
      render :partial => 'crops/planting_advice', :locals => { :crop => @crop }
      rendered.should have_content "Plant in:"
      rendered.should have_content "sun (1)"
    end

    it "shows multiple sunniness frequencies" do
      FactoryGirl.create(:sunny_planting, :crop => @crop)
      FactoryGirl.create(:sunny_planting, :crop => @crop)
      FactoryGirl.create(:shady_planting, :crop => @crop)
      render :partial => 'crops/planting_advice', :locals => { :crop => @crop }
      rendered.should have_content "Plant in:"
      rendered.should have_content "sun (2), shade (1)"
    end

  end

  context "planted from" do

    it "doesn't show planted_from if none are set" do
      render :partial => 'crops/planting_advice', :locals => { :crop => @crop }
      rendered.should have_content "Plant from: not known."
    end

    it "shows planted_from frequencies" do
      FactoryGirl.create(:seed_planting, :crop => @crop)
      render :partial => 'crops/planting_advice', :locals => { :crop => @crop }
      rendered.should have_content "Plant from:"
      rendered.should have_content "seed (1)"
    end

    it "shows multiple planted_from frequencies" do
      FactoryGirl.create(:seed_planting, :crop => @crop)
      FactoryGirl.create(:seed_planting, :crop => @crop)
      FactoryGirl.create(:cutting_planting, :crop => @crop)
      render :partial => 'crops/planting_advice', :locals => { :crop => @crop }
      rendered.should have_content "Plant from:"
      rendered.should have_content "seed (2), cutting (1)"
    end
  end

end
