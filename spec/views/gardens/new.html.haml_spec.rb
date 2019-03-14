# frozen_string_literal: true

require 'rails_helper'

describe "gardens/new" do
  before do
    @member = FactoryBot.create(:member)
    sign_in @member
    controller.stub(:current_user) { @member }
    @garden = FactoryBot.create(:garden, owner: @member)
    assign(:garden, @garden)
    render
  end

  it "renders new garden form" do
    assert_select "form", action: gardens_path, method: "post" do
      assert_select "input#garden_name", name: "garden[name]"
      assert_select "textarea#garden_description", name: "garden[description]"
      assert_select "input#garden_location", name: "garden[location]"
      assert_select "input#garden_area", name: "garden[area]"
      assert_select "select#garden_area_unit", name: "garden[area_unit]"
      assert_select "input#garden_active", name: "garden[active]"
    end
  end
end
