require 'spec_helper'

describe "gardens/new" do
  before(:each) do
    controller.stub(:current_user) { Member.new }
    assign(:garden, FactoryGirl.create(:garden))
  end

  it "renders new garden form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => gardens_path, :method => "post" do
      assert_select "input#garden_name", :name => "garden[name]"
      assert_select "textarea#garden_description", :name => "garden[description]"
      assert_select "input#garden_location", :name => "garden[location]"
      assert_select "input#garden_area", :name => "garden[area]"
      assert_select "select#garden_area_unit", :name => "garden[area_unit]"
      assert_select "input#garden_active", :name => "garden[active]"
    end
  end
end
