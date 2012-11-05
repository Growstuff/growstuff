require 'spec_helper'

describe "gardens/edit" do
  before(:each) do
    @garden = assign(:garden, stub_model(Garden,
      :name => "MyString",
      :user_id => "",
      :slug => "MyString"
    ))
  end

  it "renders the edit garden form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => gardens_path(@garden), :method => "post" do
      assert_select "input#garden_name", :name => "garden[name]"
      assert_select "input#garden_user_id", :name => "garden[user_id]"
      assert_select "input#garden_slug", :name => "garden[slug]"
    end
  end
end
