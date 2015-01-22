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

    context "SEO" do

      background do
        visit crop_path(crop)
      end

      scenario "has seed heading with SEO" do
        expect(page).to have_content "Find #{ crop.name } seeds"
      end

      scenario "has harvest heading with SEO" do
        expect(page).to have_content "#{ crop.name.capitalize } harvests"
      end

      scenario "has planting heading with SEO" do
        expect(page).to have_content "See who's planted #{ crop.name.pluralize }"
      end

      scenario "has planting advice with SEO" do
        expect(page).to have_content "How to grow #{ crop.name }"
      end

      scenario "has a link to Wikipedia with SEO" do
        expect(page).to have_content "Learn more about #{ crop.name }"
        expect(page).to have_link "Wikipedia (English)", crop.en_wikipedia_url
      end

    end
  end
end
