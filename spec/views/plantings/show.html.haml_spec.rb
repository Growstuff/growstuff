require 'spec_helper'

describe "plantings/show" do
  before(:each) do
    @planting = assign(:planting, stub_model(Planting,
      :garden_id => 1,
      :crop_id => 2,
      :quantity => 3,
      :description => "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    rendered.should match(/2/)
    rendered.should match(/3/)
    rendered.should match(/MyText/)
  end
end
