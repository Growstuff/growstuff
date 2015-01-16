require 'rails_helper'

describe "scientific_names/show" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @scientific_name = assign(:scientific_name,
      FactoryGirl.create(:zea_mays)
    )
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Zea mays/)
    rendered.should match(@scientific_name.id.to_s)
  end
end
