# frozen_string_literal: true

require 'rails_helper'

describe "photos/show" do
  let(:photo) { FactoryBot.create :photo, owner: member }
  let(:crops) { FactoryBot.create_list :crop, 2         }
  before do
    @photo = photo
    @crops = crops
  end

  let(:member) { FactoryBot.create :member }

  let(:harvest)  { FactoryBot.create :harvest, owner: member  }
  let(:planting) { FactoryBot.create :planting, owner: member }
  let(:seed)     { FactoryBot.create :seed, owner: member     }
  let(:garden)   { FactoryBot.create :garden, owner: member   }

  shared_examples "photo data renders" do
    it "shows the image" do
      assert_select "img[src='#{@photo.fullsize_url}']"
    end

    it "links to the owner's profile" do
      expect(rendered).to have_link(href: member_path(@photo.owner))
    end

    it "shows a link to the original image" do
      expect(rendered).to have_link 'View on Flickr', href: @photo.link_url
    end

    it "links to harvest" do
      assert_select "a", href: harvest_path(harvest)
    end

    it "links to planting" do
      assert_select "a", href: planting_path(planting)
    end

    it "links to garden" do
      assert_select "a", href: garden_path(garden)
    end

    it "links to seeds" do
      assert_select "a", href: seed_path(seed)
    end
  end

  shared_examples "No links to change data" do
    it "does not have a delete button" do
      assert_select "a[href='#{photo_path(@photo)}']", false
    end
  end

  context "signed in as owner" do
    before do
      controller.stub(:current_user) { member }
      render
    end

    include_examples "photo data renders"

    it "has a delete button" do
      assert_select "a[href='#{photo_path(@photo)}']"
    end
  end

  context "signed in as another member" do
    before do
      controller.stub(:current_user) { FactoryBot.create :member }
      render
    end

    include_examples "photo data renders"
    include_examples "No links to change data"
  end

  context "not signed in" do
    before do
      controller.stub(:current_user) { nil }
      render
    end

    include_examples "photo data renders"
    include_examples "No links to change data"
  end

  context "CC-licensed photo" do
    before do
      controller.stub(:current_user) { nil }
      @photo.harvests << harvest
      @photo.plantings << planting
      @photo.seeds << seed
      @photo.gardens << garden
      render
    end

    it "links to the CC license" do
      assert_select "a", href: @photo.license_url,
                         text: @photo.license_name
    end
  end

  context "unlicensed photo" do
    before do
      controller.stub(:current_user) { nil }
      @photo = assign(:photo, FactoryBot.create(:unlicensed_photo))
      render
    end

    it "contains the phrase 'All rights reserved'" do
      rendered.should have_content "All rights reserved"
    end
  end
end
