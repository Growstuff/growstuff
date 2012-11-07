require 'spec_helper'

describe "scientific_names/index" do
  before(:each) do
    assign(:scientific_names, [
      stub_model(ScientificName,
        :scientific_name => "Scientific Name",
        :crop_id => 1
      ),
      stub_model(ScientificName,
        :scientific_name => "Scientific Name",
        :crop_id => 1
      )
    ])
  end

  it "renders a list of scientific_names" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Scientific Name".to_s, :count => 2
    assert_select "tr>td", :text => 1.to_s, :count => 2
  end
end
