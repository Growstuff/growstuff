require 'spec_helper'

describe "gardens/new" do
  before(:each) do
    assign(:garden, FactoryGirl.create(:garden))
  end

  it "renders new garden form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => gardens_path, :method => "post" do
      assert_select "input#garden_name", :name => "garden[name]"
    end
  end
end
