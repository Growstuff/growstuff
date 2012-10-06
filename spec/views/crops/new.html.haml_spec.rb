require 'spec_helper'

describe "crops/new" do
  before(:each) do
    assign(:crop, stub_model(Crop,
      :system_name => "MyString",
      :en_wikipedia_url => "MyString"
    ).as_new_record)
  end

  it "renders new crop form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => crops_path, :method => "post" do
      assert_select "input#crop_system_name", :name => "crop[system_name]"
      assert_select "input#crop_en_wikipedia_url", :name => "crop[en_wikipedia_url]"
    end
  end
end
