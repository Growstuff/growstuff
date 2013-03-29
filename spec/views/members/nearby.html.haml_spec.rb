require 'spec_helper'

describe "members/nearby" do
  before(:each) do
    @member = FactoryGirl.create(:geolocated_member)
    controller.stub(:current_user) { @member }
    controller.stub(:current_member) { @member }
    @nearby_members = [FactoryGirl.create(:member)]
  end

  context "when the epicentre is the member's location" do
    before(:each) do
      @location = @member.location
      render
    end

    it "shows the member's location in the textbox" do
      assert_select "#location", :value => @location
    end

    it "shows 'Members near you' instead of naming the place" do
      view.content_for(:title).should == "Members near you"
    end 

    it "shows the names of nearby members" do
      @nearby_members.each do |m|
        rendered.should contain m.login_name
      end
    end
  end

  context "when the epicentre is somewhere else" do
    before(:each) do
      @location = "Rothera base, Adelaide Island, Antarctica"
      render
    end

    it "shows the selected location" do
      view.content_for(:title).should == "Members near #{@location}"
    end

    it "shows the selected location in the textbox" do
      assert_select "#location", :value => @location
    end

    it "shows the names of nearby members" do
      @nearby_members.each do |m|
        rendered.should contain m.login_name
      end
    end
  end

end
