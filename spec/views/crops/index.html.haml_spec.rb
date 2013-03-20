require 'spec_helper'

describe "crops/index" do
  before(:each) do
    controller.stub(:current_user) { nil }
    page = 1
    per_page = 2
    total_entries = 2
    crops = WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
      pager.replace([
        FactoryGirl.create(:tomato),
        FactoryGirl.create(:maize)
      ])
    end
    assign(:crops, crops)
  end

  it "renders a list of crops" do
    render
    assert_select "a", :text => "Maize"
    assert_select "a", :text => "Tomato"
  end

  context "logged in and crop wrangler" do
    before(:each) do
      @member = FactoryGirl.create(:crop_wrangling_member)
      sign_in @member
      controller.stub(:current_user) { @member }
      render
    end

    it "shows a new crop link" do
      rendered.should contain "New Crop"
    end
  end
end
