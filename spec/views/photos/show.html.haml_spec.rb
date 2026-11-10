# frozen_string_literal: true

require 'rails_helper'

describe "photos/show" do
  let(:photo) { create(:photo, owner: member) }
  let(:member) { create(:member) }
  let(:harvest)  { create(:harvest, owner: member)  }
  let(:planting) { create(:planting, owner: member) }
  let(:seed)     { create(:seed, owner: member)     }
  let(:garden)   { create(:garden, owner: member)   }
  let(:crops) { create_list(:crop, 2) }

  # The ability asks the controller for the user; the comment box asks the view for the member.
  def sign_in_view(signed_in_member)
    controller.stub(:current_user) { signed_in_member }
    allow(view).to receive_messages(member_signed_in?: signed_in_member.present?, current_member: signed_in_member)
  end

  before do
    @photo = photo
    @crops = crops
  end

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

  context "when signed in as the owner" do
    before do
      sign_in_view(member)
      render
    end

    include_examples "photo data renders"

    it "has a delete button" do
      assert_select "a[href='#{photo_path(@photo)}']"
    end
  end

  context "when signed in as another member" do
    before do
      sign_in_view(create(:member))
      render
    end

    include_examples "photo data renders"
    include_examples "No links to change data"
  end

  context "when not signed in" do
    before do
      sign_in_view(nil)
      render
    end

    include_examples "photo data renders"
    include_examples "No links to change data"
  end

  context "with a CC-licensed photo" do
    before do
      sign_in_view(nil)
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

  context "with an unlicensed photo" do
    before do
      sign_in_view(nil)
      @photo = assign(:photo, create(:unlicensed_photo))
      render
    end

    it "contains the phrase 'All rights reserved'" do
      expect(rendered).to have_content "All rights reserved"
    end
  end

  context "with a photo by someone who is not a member" do
    let(:photo) do
      create(:photo, owner: member, author_name: 'Pat Photo', author_url: 'https://www.flickr.com/photos/pat/',
                     license_url: 'https://creativecommons.org/licenses/by/2.0/', license_name: 'Attribution License')
    end

    before do
      sign_in_view(nil)
      render
    end

    it "credits the photographer" do
      expect(rendered).to have_content "Pat Photo"
    end

    it "links to the photographer's page on Flickr" do
      expect(rendered).to have_link href: 'https://www.flickr.com/photos/pat/'
    end

    it "does not link to the member who added it" do
      expect(rendered).to have_no_link href: member_path(member)
    end

    it "offers to copy the credit" do
      assert_select "button[data-copy-text*='Pat Photo']"
    end
  end

  context "when signed in as the owner of a Flickr photo" do
    before do
      sign_in_view(member)
      render
    end

    it "has a menu item to refresh it from Flickr" do
      assert_select ".photo-actions a.dropdown-item[href='#{refresh_photo_path(photo)}'][data-method='post']"
    end
  end

  context "with a photo attached to a planting" do
    let(:unlink_path) { photo_association_path(photo_id: photo.id, type: 'planting', id: planting.id) }

    before { photo.plantings << planting }

    context "when signed in as the owner" do
      before do
        sign_in_view(member)
        render
      end

      it "has a menu item to take the photo off the planting" do
        assert_select ".photo-actions a.dropdown-item[href='#{unlink_path}'][data-method='delete']"
      end

      it "has a menu item to delete the photo altogether" do
        assert_select ".photo-actions a.dropdown-item.text-danger[href='#{photo_path(photo)}'][data-method='delete']"
      end
    end

    context "when signed in as another member" do
      before do
        sign_in_view(create(:member))
        render
      end

      it "has no link to take the photo off the planting" do
        assert_select "a[href='#{unlink_path}']", false
      end
    end
  end
end
