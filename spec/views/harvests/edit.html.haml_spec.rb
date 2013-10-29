require 'spec_helper'

describe "harvests/edit" do
  before(:each) do
    assign(:harvest, FactoryGirl.create(:harvest))
    render
  end

  it "renders new harvest form" do
    assert_select "form", :action => harvests_path, :method => "post" do
      assert_select "select#harvest_crop_id", :name => "harvest[crop_id]"
      assert_select "select#harvest_plant_part", :name => "harvest[plant_part]"
      assert_select "input#harvest_quantity", :name => "harvest[quantity]"
      assert_select "input#harvest_weight_quantity", :name => "harvest[quantity]"
      assert_select "select#harvest_unit", :name => "harvest[unit]"
      assert_select "select#harvest_weight_unit", :name => "harvest[unit]"
      assert_select "textarea#harvest_description", :name => "harvest[description]"
    end
  end
end
