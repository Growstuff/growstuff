require 'rails_helper'

describe "plant_parts/new" do
  before(:each) do
    assign(:plant_part, stub_model(PlantPart,
      name: "MyString").as_new_record)
  end

  it "renders new plant_part form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", action: plant_parts_path, method: "post" do
      assert_select "input#plant_part_name", name: "plant_part[name]"
    end
  end
end
