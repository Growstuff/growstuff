require 'rails_helper'

describe "scientific_names/index" do
  before(:each) do
    controller.stub(:current_user) { nil }
    assign(:scientific_names, [
             FactoryBot.create(:zea_mays),
             FactoryBot.create(:solanum_lycopersicum)
           ])
  end

  it "renders a list of scientific_names" do
    render
    assert_select "tr>td", text: "Zea mays".to_s
    assert_select "tr>td", text: "Solanum lycopersicum".to_s
  end

  it "doesn't show edit/destroy links" do
    render
    rendered.should_not have_content "Edit"
    rendered.should_not have_content "Delete"
  end

  context "logged in and crop wrangler" do
    before(:each) do
      @member = FactoryBot.create(:crop_wrangling_member)
      sign_in @member
      controller.stub(:current_user) { @member }
    end

    it "shows edit/destroy links" do
      render
      rendered.should have_content "Edit"
      rendered.should have_content "Delete"
    end
  end
end
