require 'spec_helper'

describe "plant_parts/index" do
  before(:each) do
    assign(:plant_parts, [
      stub_model(PlantPart,
        :name => "Name"
      ),
      stub_model(PlantPart,
        :name => "Name"
      )
    ])
  end

  it "renders a list of plant_parts" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
  end
end
