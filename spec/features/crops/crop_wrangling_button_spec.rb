require 'rails_helper'

feature "crop wrangling button" do

  let(:crop_wrangling_member) { FactoryGirl.create(:crop_wrangler) }

    context "crop wrangling button" do

      background do
        login_as(:crop_wrangler)
        visit crops_path
      end

      scenario "has a link to crop wrangling page" do
        expect(page).to have_link "Wrangle Crops", wrangle_crops_path
      end

    end

    let(:member) { FactoryGirl.create(:member) }

    context "crop wrangling button" do

      background do
        login_as(:member)
        visit crops_path
      end

      scenario "has no link to crop wrangling page" do
        expect(page).to have_no_link "Wrangle Crops", wrangle_crops_path
      end
    end
  end
