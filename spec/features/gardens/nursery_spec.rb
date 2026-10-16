# frozen_string_literal: true

require 'rails_helper'

describe "Nursery" do
  include_context 'signed in member'

  describe "my gardens page" do
    before { visit member_gardens_path(member) }

    context "without a nursery" do
      it "offers to set one up" do
        expect(page).to have_link 'Set up a nursery'
      end

      it "says there is none" do
        expect(page).to have_content "#{member} has no seedling raising nursery"
      end
    end

    context "with seedlings in the nursery" do
      let(:crop) { create(:crop, name: 'tomato') }

      before do
        create(:planting, garden: member.nursery, owner: member, crop:, quantity: 6)
        visit member_gardens_path(member)
      end

      it "sows in a dialog" do
        click_button 'Sow seeds'
        expect(page).to have_css '.modal', text: 'Plant something in Nursery'
      end

      it "lists the seedlings above the gardens" do
        within('.nursery-panel') { expect(page).to have_link 'tomato' }
      end
    end
  end

  describe "choosing a nursery" do
    before do
      member.gardens.first.update!(name: 'Backyard')
      visit nursery_path
    end

    it "explains what a nursery is" do
      expect(page).to have_content 'where you raise seedlings'
    end

    it "can use an existing garden" do
      click_button 'Use this garden as my nursery'
      expect(member.gardens.nurseries.first.name).to eq 'Backyard'
    end

    it "can make a new nursery" do
      click_button 'Make a nursery'
      expect(member.gardens.nurseries.first.name).to eq 'Nursery'
    end

    it "can opt out" do
      click_button 'No nursery for me'
      expect(page).to have_content "#{member} has no seedling raising nursery"
    end

    it "lets them change their mind" do
      click_button 'No nursery for me'
      click_link 'Change this'
      expect(page).to have_button 'Make a nursery'
    end
  end

  describe "visiting my nursery" do
    before do
      member.nursery
      visit nursery_path
    end

    it "shows the nursery garden" do
      expect(page).to have_current_path garden_path(member.nursery)
    end
  end

  describe "using an existing garden as my nursery" do
    let(:garden) { member.gardens.first }

    before do
      visit garden_path(garden)
      click_link 'Actions'
      click_link 'Use as my nursery'
      page.assert_text 'is now your nursery'
    end

    it "marks the garden as the nursery" do
      expect(garden.reload).to be_nursery
    end

    it "says so" do
      expect(page).to have_content 'This garden is now your nursery.'
    end
  end

  describe "using a second garden as my nursery" do
    let!(:old_nursery) { member.nursery }
    let(:garden) { member.gardens.not_nurseries.first }

    before do
      visit garden_path(garden)
      click_link 'Actions'
      click_link 'Use as my nursery'
      page.assert_text 'is now your nursery'
    end

    it "makes the garden the nursery" do
      expect(garden.reload).to be_nursery
    end

    it "stops the old nursery being one" do
      expect(old_nursery.reload).not_to be_nursery
    end
  end

  describe "transplanting some seedlings" do
    let(:nursery) { member.nursery }
    let(:backyard) { create(:garden, owner: member, name: 'Backyard') }
    let!(:seedlings) { create(:planting, garden: nursery, owner: member, quantity: 12) }

    def transplant(count, to:)
      visit planting_path(seedlings)
      click_link 'Actions'
      click_link 'Transplant'
      within '#transplant-modal' do
        select to.name, from: 'Move this planting to:'
        fill_in 'How many?', with: count
        click_on 'Transplant'
      end
      expect(page).to have_content 'successfully transplanted'
    end

    before do
      backyard
      transplant(4, to: backyard)
    end

    it "plants them in the new garden" do
      expect(Planting.last).to have_attributes(garden: backyard, quantity: 4, transplanted_from: seedlings)
    end

    it "leaves the rest in the nursery" do
      expect(seedlings.reload).to have_attributes(quantity: 8, finished: false)
    end
  end
end
