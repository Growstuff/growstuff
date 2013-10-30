require 'spec_helper'

describe "plant_parts/show" do
  before(:each) do
    @plant_part = assign(:plant_part, stub_model(PlantPart,
      :name => "Name"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
  end
end
