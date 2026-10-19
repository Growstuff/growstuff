# frozen_string_literal: true

require 'rails_helper'

describe "crops/index.html.haml" do
  before do
    controller.stub(:current_user) { nil }
    page = 1
    per_page = 2
    total_entries = 2
    @tomato = create(:tomato)
    @maize  = create(:maize)
    assign(:crops, [@tomato, @maize])
    crops = [@tomato, @maize]
    assign(:pagy, Pagy::Offset.new(count: total_entries, limit: per_page, page:))
    assign(:crops, crops)
  end

  it "shows photos where available" do
    @planting = create(:planting, crop: @tomato)
    @photo = create(:photo, owner: @planting.owner)
    @planting.photos << @photo
    render
    assert_select "img", src: @photo.thumbnail_url
  end

  it "linkifies crop images" do
    render
    assert_select "img", src: :tomato
  end

  context "downloads" do
    it "offers data downloads" do
      render
      expect(rendered).to have_content "The data on this page is available in the following formats:"
      assert_select "a", href: crops_path(format: 'csv')
      assert_select "a", href: crops_path(format: 'json')
      assert_select "a", href: crops_path(format: 'rss')
    end
  end
end
