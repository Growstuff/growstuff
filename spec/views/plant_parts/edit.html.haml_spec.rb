# frozen_string_literal: true

require 'rails_helper'

describe "plant_parts/edit" do
  before do
    @plant_part = assign(:plant_part, stub_model(PlantPart,
                                                 name: "MyString"))
  end

  it "renders the edit plant_part form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", action: plant_parts_path(@plant_part), method: "post" do
      assert_select "input#plant_part_name", name: "plant_part[name]"
    end
  end
end
