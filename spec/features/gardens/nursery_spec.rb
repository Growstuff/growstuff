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
        create(:planting, garden: member.nursery, owner: member, crop:, quantity: 6, planted_at: Time.zone.today)
        create(:planting, garden: member.nursery, owner: member, crop: create(:crop, name: 'basil'),
                          planted_at: 1.week.from_now.to_date)
        visit member_gardens_path(member)
      end

      it "groups them under the day they were sown" do
        within('.nursery-panel') { expect(page).to have_css '.nursery-day-heading', text: /today/i }
      end

      it "lists plans to sow later separately" do
        within('.nursery-planned') { expect(page).to have_link 'basil' }
      end

      it "sows in a dialog" do
        click_button 'Sow seeds'
        expect(page).to have_css '.modal', text: 'Sow seeds'
      end

      it "lists the seedlings above the gardens" do
        within('.nursery-panel') { expect(page).to have_link 'tomato' }
      end
    end
  end

  describe "sowing from a seed packet" do
    let(:crop) { create(:crop, name: 'beetroot') }
    let!(:packet) { create(:seed, owner: member, crop:, quantity: 120) }

    before do
      member.nursery
      visit member_gardens_path(member)
      click_button 'Sow seeds'
      within('.modal') do
        click_button 'beetroot'
        fill_in 'How many seeds?', with: 6
        click_button 'Sow into the nursery'
      end
      page.assert_no_selector '.modal'
    end

    it "sows them into the nursery" do
      expect(member.nursery.plantings.pluck(:crop_id, :quantity, :parent_seed_id)).to eq [[crop.id, 6, packet.id]]
    end

    it "takes them out of the packet" do
      expect(packet.reload.quantity).to eq 114
    end
  end

  describe "recognising a seed packet by its photo" do
    let(:packet) { create(:seed, owner: member, crop: create(:crop, name: 'beetroot')) }

    before do
      packet.photos << create(:photo, owner: member, thumbnail_url: 'https://example.com/packet.jpg')
      member.nursery
      visit member_gardens_path(member)
      click_button 'Sow seeds'
    end

    it "shows the packet's photo in the list" do
      expect(page).to have_css "img[alt='Photo of the beetroot packet']"
    end
  end

  describe "sowing from expired seeds" do
    let(:crop) { create(:crop, name: 'beetroot') }

    before do
      create(:seed, owner: member, crop:, plant_before_year: 2020)
      member.nursery
      visit member_gardens_path(member)
      click_button 'Sow seeds'
    end

    it "marks the packet as expired in the list" do
      expect(page).to have_css '.badge', text: 'Expired 2020'
    end
  end

  describe "planting out seedlings" do
    let(:main) { member.gardens.first }
    let(:tomato) { create(:crop, name: 'cherry tomato') }
    let(:eggplant) { create(:crop, name: 'eggplant') }
    let!(:tomatoes) { create(:planting, garden: member.nursery, owner: member, crop: tomato, quantity: 6, planted_at: 5.days.ago.to_date) }
    let!(:eggplants) do
      create(:planting, garden: member.nursery, owner: member, crop: eggplant, quantity: 3, planted_at: 5.days.ago.to_date)
    end

    before do
      visit plant_out_nursery_path
      check "batch_#{tomatoes.id}"
      check "batch_#{eggplants.id}"
      choose main.name
      fill_in 'How many cherry tomato', with: 4
      click_button 'Plant out'
      page.assert_text 'Anything left in the nursery?'
    end

    it "plants out the number asked for" do
      expect(main.plantings.pluck(:crop_id, :quantity)).to contain_exactly([tomato.id, 4], [eggplant.id, 3])
    end

    it "keeps the sow date" do
      expect(main.plantings.pluck(:planted_at).uniq).to eq [5.days.ago.to_date]
    end

    it "records the day they were planted out" do
      expect(main.plantings.pluck(:transplanted_at).uniq).to eq [Time.zone.today]
    end

    it "leaves the rest in the nursery" do
      expect(tomatoes.reload).to have_attributes(quantity: 2, finished: false)
    end

    it "finishes a batch that all went out" do
      expect(eggplants.reload).to be_finished
    end
  end

  describe "after planting out some of a batch" do
    let!(:tomatoes) { create(:planting, garden: member.nursery, owner: member, quantity: 6, planted_at: 5.days.ago.to_date) }

    before do
      visit plant_out_nursery_path
      check "batch_#{tomatoes.id}"
      choose member.gardens.first.name
      fill_in "quantities_#{tomatoes.id}", with: 4
      click_button 'Plant out'
    end

    it "says how many are left" do
      expect(page).to have_content '2 seedlings still in the nursery'
    end

    it "can mark the rest as done" do
      choose "died_#{tomatoes.id}"
      click_button 'Done'
      page.assert_current_path member_gardens_path(member)
      expect(tomatoes.reload).to be_failed
    end
  end

  describe "planting out without choosing a garden" do
    before do
      create(:planting, garden: member.nursery, owner: member, quantity: 2, planted_at: 2.days.ago.to_date)
      visit plant_out_nursery_path
      click_button 'Plant out'
    end

    it "asks which garden" do
      expect(page).to have_content 'Choose which garden they are going into.'
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
