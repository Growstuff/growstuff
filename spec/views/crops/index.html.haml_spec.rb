require 'rails_helper'

describe "crops/index" do
  before(:each) do
    controller.stub(:current_user) { nil }
    page = 1
    per_page = 2
    total_entries = 2
    @tomato = FactoryBot.create(:tomato)
    @maize  = FactoryBot.create(:maize)
    assign(:crops, [@tomato, @maize])
    crops = WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
      pager.replace([@tomato, @maize])
    end
    assign(:crops, crops)
  end

  it "shows photos where available" do
    @planting = FactoryBot.create(:planting, crop: @tomato)
    @photo = FactoryBot.create(:photo)
    @planting.photos << @photo
    render
    assert_select "img", src: @photo.thumbnail_url
  end

  it "linkifies crop images" do
    render
    assert_select "img", src: :tomato
  end

  context "logged in and crop wrangler" do
    before(:each) do
      @member = FactoryBot.create(:crop_wrangling_member)
      sign_in @member
      controller.stub(:current_user) { @member }
      render
    end

    it "shows a new crop link" do
      rendered.should have_content "New Crop"
    end
  end

  context "downloads" do
    it "offers data downloads" do
      render
      rendered.should have_content "The data on this page is available in the following formats:"
      assert_select "a", href: crops_path(format: 'csv')
      assert_select "a", href: crops_path(format: 'json')
      assert_select "a", href: crops_path(format: 'rss')
    end
  end
end
