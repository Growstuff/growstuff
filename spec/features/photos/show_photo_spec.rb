require 'rails_helper'

feature "show photo page" do
  let(:photo) { create :photo }

  context "signed in member" do
    let(:member) { create :member }

    background { login_as member }

    context "linked to planting" do
      let(:planting) { create :planting }

      scenario "shows linkback to planting" do
        planting.photos << photo
        visit photo_path(photo)
        expect(page).to have_link "#{planting.crop.name} planting in #{planting.garden.name} by #{planting.owner}",
          href: planting_path(planting)
      end
    end

    context "linked to harvest" do
      let(:harvest) { create :harvest }

      scenario "shows linkback to harvest" do
        harvest.photos << photo
        visit photo_path(photo)
        expect(page).to have_link "#{harvest.crop.name} harvest by #{harvest.owner}", href: harvest_path(harvest)
      end
    end

    context "linked to garden" do
      let(:garden) { create :garden }

      scenario "shows linkback to garden" do
        garden.photos << photo
        visit photo_path(photo)
        expect(page).to have_link "garden named \"#{garden.name}\" by #{garden.owner}", href: garden_path(garden)
      end
    end

    context "linked to seed" do
      let(:seed) { create :seed }

      scenario "shows linkback to seed" do
        seed.photos << photo
        visit photo_path(photo)
        expect(page).to have_link "#{seed.crop.name} seeds belonging to #{seed.owner}", href: seed_path(seed)
      end
    end
  end
end
