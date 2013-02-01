require 'spec_helper'

describe "scientific_names/index" do
  before(:each) do
    controller.stub(:current_user) { Member.new }
    assign(:scientific_names, [
      FactoryGirl.create(:zea_mays),
      FactoryGirl.create(:solanum_lycopersicum) 
    ])
  end

  it "renders a list of scientific_names" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Zea mays".to_s
    assert_select "tr>td", :text => "Solanum lycopersicum".to_s
  end
end
