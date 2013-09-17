require 'spec_helper'

describe "harvests/edit" do
  before(:each) do
    @harvest = assign(:harvest, stub_model(Harvest,
      :crop_id => 1,
      :owner_id => 1,
      :quantity => "9.99",
      :units => "MyString",
      :notes => "MyText"
    ))
  end

  it "renders the edit harvest form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => harvests_path(@harvest), :method => "post" do
      assert_select "input#harvest_crop_id", :name => "harvest[crop_id]"
      assert_select "input#harvest_owner_id", :name => "harvest[owner_id]"
      assert_select "input#harvest_quantity", :name => "harvest[quantity]"
      assert_select "input#harvest_units", :name => "harvest[units]"
      assert_select "textarea#harvest_notes", :name => "harvest[notes]"
    end
  end
end
