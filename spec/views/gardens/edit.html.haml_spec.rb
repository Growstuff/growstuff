require 'rails_helper'

describe "gardens/edit" do
  context "logged in" do
    before(:each) do
      @owner = FactoryBot.create(:member)
      sign_in @owner
      controller.stub(:current_user) { @owner }
      @garden = assign(:garden, FactoryBot.create(:garden, owner: @owner))
      render
    end

    it "renders the edit garden form" do
      render

      # Run the generator again with the --webrat flag if you want to use webrat matchers
      assert_select "form", action: gardens_path(@garden), method: "post" do
        assert_select "input#garden_name", name: "garden[name]"
        assert_select "textarea#garden_description", name: "garden[description]"
        assert_select "input#garden_location", name: "garden[location]"
        assert_select "input#garden_area", name: "garden[area]"
        assert_select "select#garden_area_unit", name: "garden[area_unit]"
        assert_select "input#garden_active", name: "garden[active]"
      end
    end
  end
end
