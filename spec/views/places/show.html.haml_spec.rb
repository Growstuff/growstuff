# frozen_string_literal: true

require 'rails_helper'

describe "places/show" do
  before do
    @member = FactoryBot.create(:london_member)
    @nearby_members = [FactoryBot.create(:member)]
    controller.stub(:current_user) { @member }
    controller.stub(:current_member) { @member }
    @place = @member.location
    render
  end

  it "shows the selected place" do
    view.content_for(:title).should match @place
  end

  it "shows the selected place in the textbox" do
    assert_select "#new_place", value: @place
  end

  it "shows the names of nearby members" do
    @nearby_members.each do |m|
      rendered.should have_content m.login_name
    end
  end
end
