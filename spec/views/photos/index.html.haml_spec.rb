require 'rails_helper'

describe "photos/index" do
  before(:each) do
    page = 1
    per_page = 2
    total_entries = 2
    photos = WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
      pager.replace([
                      FactoryBot.create(:photo),
                      FactoryBot.create(:photo)
                    ])
    end
    assign(:photos, photos)
  end

  it "renders a gallery of photos" do
    render
    assert_select ".thumbnail", count: 2
    assert_select "img", count: 2
  end
end
