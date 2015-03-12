require 'rails_helper'

feature "crop detail page" do

  let(:crop) { FactoryGirl.create(:crop) }

  context "varieties" do
    let!(:roma1) { FactoryGirl.create(:crop, :name => 'Roma tomato 1', :parent => crop) }
    let!(:roma2) { FactoryGirl.create(:crop, :name => 'Roma tomato 2', :parent => crop) }
    let!(:roma3) { FactoryGirl.create(:crop, :name => 'Roma tomato 3', :parent => crop) }
    let!(:roma4) { FactoryGirl.create(:crop, :name => 'Roma tomato 4', :parent => crop) }

    scenario "The crop has 4 varieties" do

      visit crop_path(crop)

      # It lists all 5 items (note: including the top level item.)
      # It DOES NOT have "Show all/less" toggle link
      expect(page).to have_css('li', text: /tomato/i, count: 5)
      expect(page).to have_no_css('button', text: /Show all+/i)
      expect(page).to have_no_css('button', text: /Show less+/i)
    end

    scenario "The crop has more than 4 varieties", :js => true do
      roma5 = FactoryGirl.create(:crop, :name => 'Roma tomato 5', :parent => crop)

      visit crop_path(crop)

      # It lists the first 5 items (note: including the top level item.)
      # It HAS have "Show all" toggle link but not "Show less" link
      expect(page).to have_css('li', text: /tomato/i, count: 5)
      expect(page).to have_css('li', text: 'Roma tomato 4')
      expect(page).to have_no_css('li', text: 'Roma tomato 5')
      expect(page).to have_css('button', text: /Show all+/i)
      expect(page).to have_no_css('button', text: /Show less+/i)

      # Clik "Show all" link
      page.find('button', :text => /Show all+/).click

      # It lists all 6 items (note: including the top level item.)
      # It HAS have "Show all" toggle link but not "Show less" link
      expect(page).to have_css('li', text: /tomato/i, count: 6)
      expect(page).to have_css('li', text: 'Roma tomato 4')
      expect(page).to have_css('li', text: 'Roma tomato 5')
      expect(page).to have_no_selector('button', text: /Show all+/i)
      expect(page).to have_selector('button', text: /Show less+/i)

      # Clik "Show less" link
      page.find('button', :text => /Show less+/).click

      # It lists 5 items (note: including the top level item.)
      # It HAS have "Show all" toggle link but not "Show less" link
      expect(page).to have_css('li', text: /tomato/i, count: 5)
      expect(page).to have_css('li', text: 'Roma tomato 4')
      expect(page).to have_no_css('li', text: 'Roma tomato 5')
      expect(page).to have_selector('button', text: /Show all+/i)
      expect(page).to have_no_selector('button', text: /Show less+/i)
    end

  end

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
