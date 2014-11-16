require 'rails_helper'

describe "members/_location" do
  context "member with location" do
    before(:each) do
      @member = FactoryGirl.create(:london_member)
      render :partial => 'members/location', :locals => { :member => @member }
    end

    it 'shows location if available' do
      rendered.should contain @member.location
    end

    it "links to the places page" do
      assert_select "a", :href => place_path(@member.location)
    end
  end

  context "member with no location" do
    before(:each) do
      @member = FactoryGirl.create(:member)
      render :partial => 'members/location', :locals => { :member => @member }
    end

    it 'shows unknown location' do
      rendered.should contain "unknown location"
    end

    it "doesn't link anywhere" do
      assert_select "a", false
    end

  end

end
