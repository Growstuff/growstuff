# frozen_string_literal: true

require 'rails_helper'

describe "photos/edit" do
  before do
    @photo = assign(:photo, stub_model(Photo,
                                       owner_id:        1,
                                       flickr_photo_id: 1,
                                       thumbnail_url:   "MyString",
                                       fullsize_url:    "MyString"))
  end
end
