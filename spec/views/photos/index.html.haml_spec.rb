# frozen_string_literal: true

require 'rails_helper'

describe "photos/index" do
  before do
    page = 1
    per_page = 2
    total_entries = 2
    photos = [
                      create(:photo),
                      create(:photo)
                    ]
    assign(:pagy, Pagy::Offset.new(count: total_entries, limit: per_page, page:))
    assign(:photos, photos)
  end

  it "renders a gallery of photos" do
    render
    assert_select ".photo-card", count: 2
    assert_select "img.img-card", count: 2
  end
end
