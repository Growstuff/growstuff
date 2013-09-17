require 'spec_helper'

describe "harvests/show" do
  before(:each) do
    @harvest = assign(:harvest, stub_model(Harvest,
      :crop_id => 1,
      :owner_id => 2,
      :quantity => "9.99",
      :units => "Units",
      :notes => "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    rendered.should match(/2/)
    rendered.should match(/9.99/)
    rendered.should match(/Units/)
    rendered.should match(/MyText/)
  end
end
