# frozen_string_literal: true

require 'rails_helper'

describe "crop detail page", js: true do
  before do
    FactoryBot.create :plant_part, name: 'leaf'
  end
  subject do
    # Update the medians after all the
    # data has been loaded
    crop.reload
    crop.update_medians

    visit crop_path(crop)
    page
  end

  let(:crop) { create :crop }

  context "varieties" do
    it "The crop DOES NOT have varieties" do
      visit crop_path(crop)
      expect(page).not_to have_text 'Varieties'
    end
  end

  context 'signed in' do
    include_context "signed in member"
    context "action buttons" do
      before { subject }

      it "has a link to plant the crop" do
        click_link 'Add to my garden'
        expect(page).to have_link "add new garden"
      end
      it "has a link to harvest the crop" do
        click_link 'Record harvest'
        expect(page).to have_link "leaf"
      end
      describe "Saving seeds" do
        before { click_link 'Save seeds' }
        it { expect(page).to have_text "Will you offer these seeds for trade?" }
        it { expect(page).to have_button "locally" }
        it { expect(page).to have_button "nationally" }
        it { expect(page).to have_button "internationally" }
        it { expect(page).to have_button "Save #{crop.name} seeds." }
      end
    end

    context "SEO" do
      before { subject }

      it "has seed heading with SEO" do
        expect(page).to have_content "Find #{crop.name} seeds"
      end

      it "has harvest heading with SEO" do
        expect(page).to have_content "#{crop.name.capitalize} harvests"
      end

      it "has planting heading with SEO" do
        expect(page).to have_content "See who's planted #{crop.name.pluralize}"
      end

      it "has planting advice with SEO" do
        expect(page).to have_content "How to grow #{crop.name}"
      end

      it "has a link to Wikipedia with SEO" do
        expect(page).to have_content "Learn more about #{crop.name}"
        expect(page).to have_link "Wikipedia (English)", href: crop.en_wikipedia_url
      end

      it "has a link to OpenFarm" do
        expect(page).to have_link "OpenFarm - Growing guide"
      end

      it "has a link to gardenate" do
        expect(page).to have_link "Gardenate - Planting reminders",
                                  href: "https://www.gardenate.com/plant/#{CGI.escape crop.name}"
      end
    end
  end

  context "seed quantity for a crop" do
    let(:seed)   { create :seed, crop: crop, quantity: 20 }

    it "User not signed in" do
      visit crop_path(seed.crop)
      expect(page).not_to have_content "You have 20 seeds"
    end

    context 'signed in' do
      include_context 'signed in member'
      before { seed.update! owner: member }
      it "User signed in" do
        visit crop_path(seed.crop)
        expect(page).to have_link "You have 20 seeds of this crop."
      end
      it "click link to your owned seeds" do
        visit crop_path(seed.crop)
        click_link "You have 20 seeds of this crop."
        expect(page).to have_current_path member_seeds_path(member_slug: member.slug), ignore_query: true
      end
    end
  end

  shared_examples "predicts harvest" do
    describe 'with harvest history data' do
      before do
        # 50 days to harvest
        FactoryBot.create(:harvest, harvested_at: 150.days.ago, crop: crop,
                                    planting: FactoryBot.create(:planting, planted_at: 200.days.ago, crop: crop))
        # 20 days to harvest
        FactoryBot.create(:harvest, harvested_at: 180.days.ago, crop: crop,
                                    planting: FactoryBot.create(:planting, planted_at: 200.days.ago, crop: crop))
        # 10 days to harvest
        FactoryBot.create(:harvest, harvested_at: 190.days.ago, crop: crop,
                                    planting: FactoryBot.create(:planting, planted_at: 200.days.ago, crop: crop))
        crop.update_medians
      end

      it "predicts harvest" do
        expect(subject).to have_text("First harvest expected 3 weeks after planting")
      end
    end
  end

  context 'predictions' do
    let!(:planting) do
      FactoryBot.create(:planting, crop:        crop,
                                   planted_at:  100.days.ago,
                                   finished_at: 1.day.ago)
    end

    context 'crop is an Annual' do
      let(:crop) { FactoryBot.create(:annual_crop) }

      describe 'with harvests' do
        include_examples "predicts harvest"
      end

      it "predicts lifespan" do
        expect(subject).to have_text "Median lifespan"
        expect(subject).to have_text "14 weeks"
      end

      it "describes Annual crops" do
        expect(subject).to have_text("living and reproducing in a single year or less")
        expect(subject).to have_text('Annual')
      end
    end

    context 'crop is Perennial' do
      let(:crop) { FactoryBot.create :perennial_crop }

      describe 'with no harvests' do
      end

      describe 'with harvests' do
        include_examples "predicts harvest"
      end

      it "describes Perennial crops" do
        expect(subject).to have_text("Perennial")
        expect(subject).to have_text("living more than two years")
      end
    end

    context 'crop Perennial value is null' do
      let(:crop) { FactoryBot.create :crop, perennial: nil }

      describe 'with no harvests' do
      end

      describe 'with harvests' do
        include_examples "predicts harvest"
      end
    end
  end

  context 'Annual and Perennial' do
    before { visit crop_path(crop) }

    context 'crop is an Annual' do
      let(:crop) { FactoryBot.create :annual_crop }

      it { expect(page).to have_text 'Annual' }
      it { expect(page).to have_text 'living and reproducing in a single year or less' }
      it { expect(page).not_to have_text 'Perennial' }
    end

    context 'crop is Perennial' do
      let(:crop) { FactoryBot.create :perennial_crop }

      it { expect(page).to have_text 'Perennial' }
      it { expect(page).to have_text 'living more than two years' }
      it { expect(page).not_to have_text 'Annual' }
    end

    context 'crop Perennial value is null' do
      let(:crop) { FactoryBot.create :crop, perennial: nil }

      it { expect(page).not_to have_text 'Perennial' }
      it { expect(page).not_to have_text 'Annual' }
    end
  end
end
