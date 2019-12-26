# frozen_string_literal: true

require 'rails_helper'

describe "new photo page" do
  context "signed in member" do
    include_context 'signed in member'
    context "viewing a planting" do
      let(:planting) { FactoryBot.create :planting, owner: member }

      it "add photo" do
        visit planting_path(planting)
        click_link 'Actions'
        within '.planting-actions' do
          click_link('Add photo')
        end
        expect(page).to have_text planting.crop.name
        Percy.snapshot(page, name: 'Add photo to planting')
      end
    end

    context "viewing a harvest" do
      let(:harvest) { FactoryBot.create :harvest, owner: member }

      it "add photo" do
        visit harvest_path(harvest)
        click_link 'Actions'
        within '.harvest-actions' do
          click_link "Add photo"
        end
        expect(page).to have_text harvest.crop.name
      end
    end

    context "viewing a garden" do
      let(:garden) { FactoryBot.create :garden, owner: member }

      it "add photo" do
        visit garden_path(garden)
        click_link 'Actions'
        within '.garden-actions' do
          click_link "Add photo"
        end
        expect(page).to have_text garden.name
      end
    end

    describe "viewing a seed" do
      let(:seed) { FactoryBot.create :seed, owner: member }

      it "add photo" do
        visit seed_path(seed)
        click_link 'Actions'
        first('.seed-actions').click_link('Add photo')
        expect(page).to have_text seed.to_s
      end
    end
  end
end
