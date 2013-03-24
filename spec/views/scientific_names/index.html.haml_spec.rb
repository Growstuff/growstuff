require 'spec_helper'

describe "scientific_names/index" do
  before(:each) do
    controller.stub(:current_user) { nil }
    assign(:scientific_names, [
      FactoryGirl.create(:zea_mays),
      FactoryGirl.create(:solanum_lycopersicum)
    ])
  end

  it "renders a list of scientific_names" do
    render
    assert_select "tr>td", :text => "Zea mays".to_s
    assert_select "tr>td", :text => "Solanum lycopersicum".to_s
  end

  it "doesn't show edit/destroy links" do
    render
    rendered.should_not contain "Edit"
    rendered.should_not contain "Delete"
  end

  context "logged in and crop wrangler" do
    before(:each) do
      @member = FactoryGirl.create(:crop_wrangling_member)
      sign_in @member
      controller.stub(:current_user) { @member }
    end

    it "shows edit/destroy links" do
      render
      rendered.should contain "Edit"
      rendered.should contain "Delete"
    end
  end
end
