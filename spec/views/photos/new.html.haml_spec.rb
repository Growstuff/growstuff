# frozen_string_literal: true

require 'rails_helper'

describe "photos/new" do
  before do
    @member = FactoryBot.create(:member)
    controller.stub(:current_user) { @member }
    page = 1
    per_page = 2
    total_entries = 2
    photos = WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
      pager.replace([])
    end
    assign(:photos, photos)
    assign(:flickr_auth, FactoryBot.create(:flickr_authentication, member: @member))
  end

  context "user has no photosets" do
    it "doesn't show a dropdown with sets from Flickr" do
      render
      assert_select "select#set", false
    end
  end

  context "user has photosets" do
    before do
      assign(:sets, "foo" => "bar") # Hash of names => IDs
    end

    it "shows a dropdown with sets from Flickr" do
      render
      assert_select "select#set"
    end

    it "shows the current photoset" do
      assign(:current_set, "bar") # the ID of the set
      render
      assert_select "h2", "foo" # the name of the set
    end
  end
end
