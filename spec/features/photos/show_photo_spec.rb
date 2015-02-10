require 'rails_helper'

feature "show photo page" do

  let (:photo) { FactoryGirl.create(:photo) }

  context "signed in member" do
    let (:member) { FactoryGirl.create(:member) }

    background do
      login_as(member)
    end

    context "linked to planting" do
      let (:planting) { FactoryGirl.create(:planting) }

      scenario "shows linkback to planting" do
        planting.photos << photo
        visit photo_path(photo)
        expect(page).to have_link planting, :href => planting_path(planting)
      end
    end

    context "linked to harvest" do
      let (:harvest) { FactoryGirl.create(:harvest) }

      scenario "shows linkback to harvest" do
        harvest.photos << photo
        visit photo_path(photo)
        expect(page).to have_link harvest, :href => harvest_path(harvest)
      end
    end

    context "linked to garden" do
      let (:garden) { FactoryGirl.create(:garden) }

      scenario "shows linkback to garden" do
        garden.photos << photo
        visit photo_path(photo)
        expect(page).to have_link garden, :href => garden_path(garden)
      end

    end

  end

end

