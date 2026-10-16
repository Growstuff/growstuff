# frozen_string_literal: true

require 'rails_helper'

describe "Nursery" do
  include_context 'signed in member'

  describe "finding it from my gardens" do
    before { visit member_gardens_path(member) }

    it "links to the nursery" do
      click_link 'Your nursery'
      expect(page).to have_css '.badge', text: 'Nursery'
    end
  end

  describe "visiting the nursery" do
    before { visit nursery_path }

    it "makes the nursery" do
      expect(member.gardens.nurseries.count).to eq 1
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
