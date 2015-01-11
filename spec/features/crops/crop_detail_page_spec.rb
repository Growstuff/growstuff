require 'rails_helper'

feature "crop detail page" do

  let(:crop) { FactoryGirl.create(:crop) }

  context "signed in member" do
    let(:member) { FactoryGirl.create(:member) }

    background do
      login_as(member)
    end

    context "action buttons" do

      background do
        visit crop_path(crop)
      end

      scenario "has a link to plant the crop" do
        expect(page).to have_link "Plant this", :href => new_planting_path(:crop_id => crop.id)
      end
      scenario "has a link to harvest the crop" do
        expect(page).to have_link "Harvest this", :href => new_harvest_path(:crop_id => crop.id)
      end
      scenario "has a link to add seeds" do
        expect(page).to have_link "Add seeds to stash", :href => new_seed_path(:crop_id => crop.id)
      end

    end
  end
end
