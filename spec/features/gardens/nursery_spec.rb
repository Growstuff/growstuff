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

      it "asks where they start their seeds" do
        expect(page).to have_content 'Where do you start your seeds?'
      end
    end

    context "with seedlings in the nursery" do
      let(:crop) { create(:crop, name: 'tomato') }

      before do
        create(:planting, garden: member.nursery!, owner: member, crop:, quantity: 6, planted_at: Time.zone.today)
        visit member_gardens_path(member)
      end

      it "draws each batch with its crop icon" do
        within('.nursery-panel') { expect(page).to have_css 'img.crop-icon[src]:not([src=""])' }
      end

      it "gives each batch a menu without harvest and save seeds, which seedlings don't have" do
        within('.nursery-panel') { click_link 'Actions for tomato' }
        expect(page).to have_link('Mark as finished')
        expect(page).to have_no_link('Record harvest')
        expect(page).to have_no_link('Save seeds')
      end

      it "opens add photo in a dialog over the page" do
        within('.nursery-panel') do
          click_link 'Actions for tomato'
          click_link 'Add photo'
        end
        expect(page).to have_css '.modal'
        expect(page).to have_current_path member_gardens_path(member)
      end

      it "names each batch by its crop, not who planted it where" do
        within('.nursery-panel') { expect(page).to have_no_content 'planting in' }
      end

      it "groups them under the day they were sown" do
        within('.nursery-panel') { expect(page).to have_css '.nursery-day-heading', text: 'Today' }
      end

      it "sows in a dialog" do
        open_sow_dialog
        expect(page).to have_css '.modal', text: 'Sow seeds'
      end

      it "lists the seedlings above the gardens" do
        within('.nursery-panel') { expect(page).to have_link 'tomato' }
      end
    end
  end

  describe "sowing from a seed packet" do
    let(:crop) { create(:crop, name: 'beetroot') }
    let!(:packet) { create(:seed, owner: member, crop:, quantity: 120, plant_before: nil) }

    before do
      member.nursery!
      visit member_gardens_path(member)
      open_sow_dialog
      within('.modal') do
        click_button 'beetroot'
        fill_in 'How many seeds?', with: 6
        click_button 'Next'
        fill_in 'Do you have any notes for this planting? (optional)', with: 'Soaked overnight'
        click_button 'Sow into the nursery'
      end
      page.assert_text '6 seedlings', wait: 10
    end

    it "saves the notes with the planting" do
      expect(member.nursery!.plantings.first.description).to eq 'Soaked overnight'
    end

    it "sows them into the nursery" do
      expect(member.nursery!.plantings.pluck(:crop_id, :quantity, :parent_seed_id)).to eq [[crop.id, 6, packet.id]]
    end

    it "takes them out of the packet" do
      expect(packet.reload.quantity).to eq 114
    end
  end

  describe "recognising a seed packet by its photo" do
    let(:packet) { create(:seed, owner: member, crop: create(:crop, name: 'beetroot'), plant_before: nil) }

    before do
      packet.photos << create(:photo, owner: member, thumbnail_url: 'https://example.com/packet.jpg')
      member.nursery!
      visit member_gardens_path(member)
      open_sow_dialog
    end

    it "shows the packet's photo in the list" do
      expect(page).to have_css "img[alt='Photo of the beetroot packet']"
    end
  end

  describe "sowing from expired seeds" do
    let(:crop) { create(:crop, name: 'beetroot') }

    before do
      create(:seed, owner: member, crop:, plant_before_year: 2020)
      member.nursery!
      visit member_gardens_path(member)
      open_sow_dialog
    end

    it "leaves expired packets out of the list" do
      within('.modal') do
        expect(page).to have_no_button 'beetroot'
        expect(page).to have_content '1 expired packet is hidden'
      end
    end

    context "when asked to include expired seeds" do
      before { within('.modal') { check 'Include expired seeds' } }

      it "lists them, marked as expired" do
        within('.modal') { expect(page).to have_css '.badge', text: 'Expired 2020' }
      end
    end
  end

  describe "choosing a seed packet" do
    let(:crop) { create(:crop, name: 'beetroot', description: 'A sweet red root.') }

    before do
      create(:seed, owner: member, crop:, plant_before: nil)
      member.nursery!
      visit member_gardens_path(member)
      open_sow_dialog
      within('.modal') { click_button 'beetroot' }
    end

    it "shows the packet with the crop's name" do
      within('.modal') { expect(page).to have_css '.seed-packet-label', text: /beetroot/i }
    end

    it "goes on to where and when" do
      within('.modal') { expect(page).to have_content 'Where are you sowing them?' }
    end

    it "goes back to the list to change the seeds" do
      within('.modal') do
        click_button 'Change seeds'
        expect(page).to have_field 'Search your seeds'
      end
    end

    it "does not add the crop's description" do
      within('.modal') { expect(page).to have_no_content 'A sweet red root.' }
    end
  end

  describe "choosing a crop for new seeds" do
    let!(:crop) { create(:crop, name: 'beetroot', description: 'A sweet red root.', sun_requirements: 'full sun') }

    before do
      member.nursery!
      visit member_gardens_path(member)
      open_sow_dialog
      within('.modal') do
        find('label', text: 'New seeds').click
        fill_in 'Which crop?', with: 'beet'
        find('[role=option]', text: 'beetroot').click
      end
    end

    it "shows what the crop is" do
      within('.modal') { expect(page).to have_content 'A sweet red root.' }
    end

    it "shows how it grows" do
      within('.modal') { expect(page).to have_content 'full sun' }
    end
  end

  describe "sowing straight into a garden" do
    let(:crop) { create(:crop, name: 'beetroot') }
    let(:garden) { member.gardens.first }

    before do
      create(:seed, owner: member, crop:, quantity: 50, plant_before: nil)
      member.nursery!
      visit member_gardens_path(member)
      open_sow_dialog
      within('.modal') do
        click_button 'beetroot'
        find('label', text: 'Straight into a garden').click
        click_button 'Next'
        click_button "Sow into #{garden.name}"
      end
    end

    it "offers to place it on the garden layout" do
      expect(page).to have_link 'Place on the garden layout', href: "/gardens/#{garden.slug}/layout"
    end

    it "plants it in the garden" do
      page.assert_text 'Where in the garden did you put them?'
      expect(garden.plantings.pluck(:crop_id)).to eq [crop.id]
    end
  end

  describe "editing a batch from its menu" do
    let!(:batch) { create(:planting, garden: member.nursery!, owner: member, quantity: 6, planted_at: Time.zone.today) }

    before do
      visit member_gardens_path(member)
      within('.nursery-panel') { click_link "Actions for #{batch.display_name}" }
      click_link 'Edit'
    end

    it "opens a dialog over the page" do
      expect(page).to have_css '.modal', text: 'What did you plant?'
    end

    it "saves, and shows the change, without leaving or reloading the page" do
      page.execute_script('window.notReloaded = true')
      within('.modal') do
        fill_in 'How many?', with: 9
        click_button 'Save'
      end
      expect(page).to have_css '.nursery-panel', text: "\u00d7 9"
      expect(page.evaluate_script('window.notReloaded')).to be true
    end
  end

  describe "transplanting a batch from its menu" do
    let(:other_garden) { member.gardens.first }
    let!(:batch) { create(:planting, garden: member.nursery!, owner: member, quantity: 6, planted_at: 3.days.ago.to_date) }

    before do
      other_garden
      visit member_gardens_path(member)
      page.execute_script('window.notReloaded = true')
      within('.nursery-panel') { click_link "Actions for #{batch.display_name}" }
      click_link 'Transplant'
      within('.modal') do
        choose other_garden.name
        click_button 'Transplant'
      end
      page.assert_no_selector '.modal', wait: 10
    end

    it "shows it in the garden and not the nursery, without reloading the page" do
      expect(page).to have_css "[data-garden-id='#{other_garden.id}'] .chip", text: batch.display_name, visible: :all
      expect(page).to have_no_css '.nursery-panel .nursery-batch'
      expect(page.evaluate_script('window.notReloaded')).to be true
    end

    it "moves the batch to the garden" do
      expect(batch.reload).to have_attributes(garden: other_garden, quantity: 6, finished: false)
    end

    it "does not make another planting" do
      expect(Planting.count).to eq 1
    end

    it "remembers it was in the nursery" do
      expect(batch.histories.map(&:garden)).to eq [batch.histories.first.garden]
      expect(batch.histories.first.garden).to be_nursery
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
      page.assert_text 'is now your nursery'
      expect(member.gardens.nurseries.first.name).to eq 'Backyard'
    end

    it "can make a new nursery" do
      click_button 'Make a nursery'
      page.assert_text 'is now your nursery'
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
      member.nursery!
      visit nursery_path
    end

    it "shows the nursery garden" do
      expect(page).to have_current_path garden_path(member.nursery!)
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
    let!(:old_nursery) { member.nursery! }
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
end
