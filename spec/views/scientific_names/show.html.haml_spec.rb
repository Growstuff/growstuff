require 'spec_helper'

describe "scientific_names/show" do
  before(:each) do
    @scientific_name = assign(:scientific_name, stub_model(ScientificName,
      :scientific_name => "Scientific Name",
      :crop_id => 1
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Scientific Name/)
    rendered.should match(/1/)
  end
end
