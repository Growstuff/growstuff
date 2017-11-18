require 'rails_helper'

feature "new photo page" do
  let(:photo) { FactoryBot.create :photo }

  context "signed in member" do
    let(:member) { FactoryBot.create :member }

    background { login_as member }

    context "viewing a planting" do
      let(:planting) { FactoryBot.create :planting, owner: member }

      scenario "add photo" do
        visit planting_path(planting)
        click_link('Add photo', match: :first)
        expect(page).to have_text planting.crop.name
      end
    end

    context "viewing a harvest" do
      let(:harvest) { FactoryBot.create :harvest, owner: member }

      scenario "add photo" do
        visit harvest_path(harvest)
        click_link "Add photo"
        expect(page).to have_text harvest.crop.name
      end
    end

    context "viewing a garden" do
      let(:garden) { FactoryBot.create :garden, owner: member }

      scenario "add photo" do
        visit garden_path(garden)
        click_link "Add photo"
        expect(page).to have_text garden.name
      end
    end

    pending "viewing a seed" do
      let(:seed) { FactoryBot.create :seed, owner: member }

      scenario "add photo" do
        visit seed_path(seed)
        click_link "Add photo"
        expect(page).to have_text seed.to_s
      end
    end
  end
end
