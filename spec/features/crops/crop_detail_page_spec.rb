require 'rails_helper'

feature "crop detail page", js: true do
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
    scenario "The crop DOES NOT have varieties" do
      visit crop_path(crop)

      within ".varieties" do
        expect(page).to have_no_selector('li', text: /tomato/i)
        expect(page).to have_no_selector('button', text: /Show+/i)
      end
    end

    scenario "The crop has one variety" do
      create :crop, name: 'Roma tomato 1', parent: crop

      subject

      within ".varieties" do
        # It lists all 2 items (note: including the top level item.)
        expect(page).to have_selector('li', text: /tomato/i, count: 2)
        # It DOES NOT have "Show all/less" toggle link
        expect(page).to have_no_selector('button', text: /Show+/i)
      end
    end

    context "many" do
      let!(:roma1) { create :crop, name: 'Roma tomato 1', parent: crop }
      let!(:roma2) { create :crop, name: 'Roma tomato 2', parent: crop }
      let!(:roma3) { create :crop, name: 'Roma tomato 3', parent: crop }
      let!(:roma4) { create :crop, name: 'Roma tomato 4', parent: crop }

      scenario "The crop has 4 varieties" do
        subject

        within ".varieties" do
          # It lists all 5 items (note: including the top level item.)
          expect(page).to have_selector('li', text: /tomato/i, count: 5)
          # It DOES NOT have "Show all/less" toggle link
          expect(page).to have_no_selector('button', text: /Show+/i)
        end
      end

      scenario "The crop has 5 varieties, including grandchild", js: true do
        create :crop, name: 'Roma tomato child 1', parent: roma4

        subject

        within ".varieties" do
          # It lists the first 5 items (note: including the top level item.)
          # It HAS have "Show all" toggle link but not "Show less" link
          expect(page).to have_selector('li', text: /tomato/i, count: 5)
          expect(page).to have_selector('li', text: 'Roma tomato 4')
          expect(page).to have_no_selector('li', text: 'Roma tomato child 1')
          # It shows the total number (5) correctly
          expect(page).to have_selector('button', text: /Show all 5 +/i)
          expect(page).to have_no_selector('button', text: /Show less+/i)

          # Clik "Show all" link
          page.find('button', text: /Show all+/).click

          # It lists all 6 items (note: including the top level item.)
          # It HAS have "Show less" toggle link but not "Show all" link
          expect(page).to have_selector('li', text: /tomato/i, count: 6)
          expect(page).to have_selector('li', text: 'Roma tomato 4')
          expect(page).to have_selector('li', text: 'Roma tomato child 1')
          expect(page).to have_no_selector('button', text: /Show all+/i)
          expect(page).to have_selector('button', text: /Show less+/i)

          # Clik "Show less" link
          page.find('button', text: /Show less+/).click

          # It lists 5 items (note: including the top level item.)
          # It HAS have "Show all" toggle link but not "Show less" link
          expect(page).to have_selector('li', text: /tomato/i, count: 5)
          expect(page).to have_selector('li', text: 'Roma tomato 4')
          expect(page).to have_no_selector('li', text: 'Roma tomato child 1')
          expect(page).to have_selector('button', text: /Show all 5 +/i)
          expect(page).to have_no_selector('button', text: /Show less+/i)
        end
      end
    end
  end

  context "signed in member" do
    let(:member) { create :member }

    background do
      login_as(member)
    end

    context "action buttons" do
      background { subject }

      scenario "has a link to plant the crop" do
        expect(page).to have_link "Plant this", href: new_planting_path(crop_id: crop.id)
      end
      scenario "has a link to harvest the crop" do
        expect(page).to have_link "Harvest this", href: new_harvest_path(crop_id: crop.id)
      end
      scenario "has a link to add seeds" do
        expect(page).to have_link "Add seeds to stash", href: new_seed_path(crop_id: crop.id)
      end
    end

    context "SEO" do
      background { subject }

      scenario "has seed heading with SEO" do
        expect(page).to have_content "Find #{crop.name} seeds"
      end

      scenario "has harvest heading with SEO" do
        expect(page).to have_content "#{crop.name.capitalize} harvests"
      end

      scenario "has planting heading with SEO" do
        expect(page).to have_content "See who's planted #{crop.name.pluralize}"
      end

      scenario "has planting advice with SEO" do
        expect(page).to have_content "How to grow #{crop.name}"
      end

      scenario "has a link to Wikipedia with SEO" do
        expect(page).to have_content "Learn more about #{crop.name}"
        expect(page).to have_link "Wikipedia (English)", href: crop.en_wikipedia_url
      end

      scenario "has a link to OpenFarm" do
        expect(page).to have_link "OpenFarm - Growing guide",
          href: "https://openfarm.cc/en/crops/#{URI.escape crop.name}"
      end

      scenario "has a link to gardenate" do
        expect(page).to have_link "Gardenate - Planting reminders",
          href: "http://www.gardenate.com/plant/#{URI.escape crop.name}"
      end
    end
  end

  context "seed quantity for a crop" do
    let(:member) { create :member }
    let(:seed) { create :seed, crop: crop, quantity: 20, owner: member }

    scenario "User not signed in" do
      visit crop_path(seed.crop)
      expect(page).not_to have_content "You have 20 seeds of this crop"
      expect(page).not_to have_content "You don't have any seeds of this crop"
      expect(page).not_to have_link "View your seeds"
    end

    scenario "User signed in" do
      login_as(member)
      visit crop_path(seed.crop)
      expect(page).to have_content "You have 20 seeds of this crop."
      expect(page).to have_link "View your seeds"
    end

    scenario "click link to your owned seeds" do
      login_as(member)
      visit crop_path(seed.crop)
      click_link "View your seeds"
      expect(current_path).to eq seeds_by_owner_path(owner: member.slug)
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
        is_expected.to have_text("First harvest expected 20 days after planting")
      end
    end
  end

  context 'predictions' do
    let!(:planting) do
      FactoryBot.create(:planting, crop: crop,
                                   planted_at: 100.days.ago,
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
        is_expected.to have_text "Median lifespan"
        is_expected.to have_text "99 days"
      end

      it "describes annual crops" do
        is_expected.to have_text(
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
        is_expected.to have_text("#{crop.name} is a perennial crop (living more than two years)")
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
