require 'spec_helper'

describe "places/show" do
  before(:each) do
    @member = FactoryGirl.create(:london_member)
    @nearby_members = [FactoryGirl.create(:member)]
    controller.stub(:current_user) { @member }
    controller.stub(:current_member) { @member }
    @place = @member.location
    render
  end

  it "shows the selected place" do
    view.content_for(:title).should match @place
  end

  it "shows the selected place in the textbox" do
    assert_select "#new_place", :value => @place
  end

  it "shows the names of nearby members" do
    @nearby_members.each do |m|
      rendered.should contain m.login_name
    end
  end

end
