require 'rails_helper'

describe "crop detail page", js: true do
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

      within ".varieties" do
        expect(page).not_to have_text 'tomato'
      end
    end
  end

  context "signed in member" do
    let(:member) { create :member }

    before do
      login_as(member)
    end

    context "action buttons" do
      before { subject }

      it "has a link to plant the crop" do
        expect(page).to have_link "Plant #{crop.name}", href: new_planting_path(crop_id: crop.id)
      end
      it "has a link to harvest the crop" do
        expect(page).to have_link "Harvest #{crop.name}", href: new_harvest_path(crop_id: crop.id)
      end
      it "has a link to add seeds" do
        expect(page).to have_link "Add #{crop.name} seeds to stash", href: new_seed_path(crop_id: crop.id)
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
        expect(page).to have_link "OpenFarm - Growing guide",
          href: "https://openfarm.cc/en/crops/#{CGI.escape crop.name}"
      end

      it "has a link to gardenate" do
        expect(page).to have_link "Gardenate - Planting reminders",
          href: "http://www.gardenate.com/plant/#{CGI.escape crop.name}"
      end
    end
  end

  context "seed quantity for a crop" do
    let(:member) { create :member                                        }
    let(:seed)   { create :seed, crop: crop, quantity: 20, owner: member }

    it "User not signed in" do
      visit crop_path(seed.crop)
      expect(page).not_to have_content "You have 20 seeds"
    end

    it "User signed in" do
      login_as(member)
      visit crop_path(seed.crop)
      expect(page).to have_link "You have 20 seeds of this crop."
    end

    it "click link to your owned seeds" do
      login_as(member)
      visit crop_path(seed.crop)
      click_link "You have 20 seeds of this crop."
      expect(current_path).to eq member_seeds_path(member_slug: member.slug)
    end
  end

  shared_examples "predicts harvest" do
    describe 'with harvest history data' do
      before do
        # 50 days to harvest
        FactoryBot.create(:harvest, harvested_at: 150.days.ago, crop: planting.crop,
                                    planting: FactoryBot.create(:planting, planted_at: 200.days.ago, crop: crop))
        # 20 days to harvest
        FactoryBot.create(:harvest, harvested_at: 180.days.ago, crop: planting.crop,
                                    planting: FactoryBot.create(:planting, planted_at: 200.days.ago, crop: crop))
        # 10 days to harvest
        FactoryBot.create(:harvest, harvested_at: 190.days.ago, crop: planting.crop,
                                    planting: FactoryBot.create(:planting, planted_at: 200.days.ago, crop: crop))
        planting.crop.update_medians
      end

      it "predicts harvest" do
        expect(subject).to have_text("First harvest expected 20 days after planting")
      end
    end
  end

  context 'predictions' do
    let!(:planting) do
      FactoryBot.create(:planting, crop:        crop,
                                   planted_at:  100.days.ago,
                                   finished_at: 1.day.ago)
    end

    context 'crop is an annual' do
      let(:crop) { FactoryBot.create(:annual_crop) }

      describe 'with no harvests' do
      end

      describe 'with harvests' do
        include_examples "predicts harvest"
      end

      it "predicts lifespan" do
        expect(subject).to have_text "Median lifespan"
        expect(subject).to have_text "99 days"
      end

      it "describes annual crops" do
        expect(subject).to have_text(
          "#{crop.name} is an annual crop (living and reproducing in a single year or less)"
        )
      end
    end

    context 'crop is perennial' do
      let(:crop) { FactoryBot.create :perennial_crop }

      describe 'with no harvests' do
      end

      describe 'with harvests' do
        include_examples "predicts harvest"
      end

      it "describes perennial crops" do
        expect(subject).to have_text("#{crop.name} is a perennial crop (living more than two years)")
      end
    end

    context 'crop perennial value is null' do
      let(:crop) { FactoryBot.create :crop, perennial: nil }

      describe 'with no harvests' do
      end

      describe 'with harvests' do
        include_examples "predicts harvest"
      end
    end
  end

  context 'annual and perennial' do
    before { visit crop_path(crop) }

    context 'crop is an annual' do
      let(:crop) { FactoryBot.create :annual_crop }

      it { expect(page).to have_text 'annual crop (living and reproducing in a single year or less)' }
      it { expect(page).not_to have_text 'perennial crop (living more than two years)' }
    end

    context 'crop is perennial' do
      let(:crop) { FactoryBot.create :perennial_crop }

      it { expect(page).to have_text 'perennial crop (living more than two years)' }
      it { expect(page).not_to have_text 'annual crop (living and reproducing in a single year or less)' }
    end

    context 'crop perennial value is null' do
      let(:crop) { FactoryBot.create :crop, perennial: nil }

      it { expect(page).not_to have_text 'perennial crop (living more than two years)' }
      it { expect(page).not_to have_text 'annual crop (living and reproducing in a single year or less)' }
    end
  end
end
