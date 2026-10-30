# frozen_string_literal: true

require 'rails_helper'

describe "photos/new" do
  before do
    @member = create(:member)
    controller.stub(:current_user) { @member }
    page = 1
    per_page = 2
    total_entries = 2
    photos = WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
      pager.replace([])
    end
    assign(:photos, photos)
    assign(:flickr_auth, create(:flickr_authentication, member: @member))
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

  context "when picking a photo of a seed packet's front" do
    let(:photo) { Struct.new(:id, :title, :farm, :server, :secret).new('1', 'Radish', 66, '65535', 'abc') }

    before do
      assign(:type, 'seed')
      assign(:id, '5')
      assign(:label, 'front')
      assign(:photos, WillPaginate::Collection.create(1, 2, 1) { |pager| pager.replace([photo]) })
      render
    end

    it "carries the label in the search form" do
      assert_select "form input[type=hidden][name=label][value=front]"
    end

    it "carries the label in the link that adds the photo" do
      assert_select "a[data-method=post][href*='label=front']"
    end
  end

  context "when picking a photo with no label" do
    before do
      assign(:type, 'seed')
      assign(:id, '5')
      render
    end

    it "does not add a label to the search form" do
      assert_select "form input[name=label]", false
    end
  end
end
