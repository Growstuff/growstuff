require 'spec_helper'

describe "plantings/edit" do
  before(:each) do
    @planting = assign(:planting, stub_model(Planting,
      :garden_id => 1,
      :crop_id => 1,
      :quantity => 1,
      :description => "MyText"
    ))
  end

  it "renders the edit planting form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => plantings_path(@planting), :method => "post" do
      assert_select "input#planting_garden_id", :name => "planting[garden_id]"
      assert_select "input#planting_crop_id", :name => "planting[crop_id]"
      assert_select "input#planting_quantity", :name => "planting[quantity]"
      assert_select "textarea#planting_description", :name => "planting[description]"
    end
  end
end
