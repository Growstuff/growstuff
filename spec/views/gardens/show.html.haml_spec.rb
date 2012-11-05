require 'spec_helper'

describe "gardens/show" do
  before(:each) do
    @garden = assign(:garden, stub_model(Garden,
      :name => "Name",
      :user_id => "",
      :slug => "Slug"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
    rendered.should match(//)
    rendered.should match(/Slug/)
  end
end
