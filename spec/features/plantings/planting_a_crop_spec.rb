# frozen_string_literal: true

require "rails_helper"
require 'custom_matchers'

describe "Planting a crop", :js, :search do
  let!(:maize) { FactoryBot.create :maize }
  let(:garden) { FactoryBot.create :garden, owner: member, name: 'Orchard' }
  let!(:planting) do
    FactoryBot.create :planting, garden: garden, owner: member, planted_at: Date.parse("2013-03-10")
  end

  before { Planting.reindex }

  context 'signed in' do
    include_context 'signed in member'
    before { visit new_planting_path }

    it_behaves_like "crop suggest", "planting"

    it "has the required fields help text" do
      expect(page).to have_content "* denotes a required field"
    end

    describe "displays required and optional fields properly" do
      it { expect(page).to have_selector ".required", text: "What did you plant?" }
      it { expect(page).to have_selector ".required", text: "Where did you plant it?" }
      it { expect(page).to have_selector 'input#planting_planted_at' }
      it { expect(page).to have_selector 'input#planting_quantity' }
      it { expect(page).to have_selector 'select#planting_planted_from' }
      it { expect(page).to have_selector 'select#planting_sunniness' }
      it { expect(page).to have_selector 'textarea#planting_description' }
      it { expect(page).to have_selector 'input#planting_finished_at' }
    end

    describe "Creating a new planting" do
      before do
        fill_autocomplete "crop", with: "mai"
        select_from_autocomplete "maize"
        within "form#new_planting" do
          fill_in "How many?", with: 42
          select "cutting", from: "Planted from"
          select "semi-shade", from: "Sun or shade?"
          fill_in "Tell us more about it", with: "It's rad."
          choose 'Garden'
          fill_in "When", with: "2014-06-15"
          click_button "Save"
        end
      end

      it { expect(page).to have_content "planting was successfully created" }
    end

    describe "Clicking link to owner's profile" do
      before do
        visit member_plantings_path(member)
        within '.login-name' do
          click_link member.login_name
        end
      end
      it { expect(page).to have_current_path member_path(member), ignore_query: true }
    end

    describe "Progress bar status on planting creation" do
      before do
        visit new_planting_path

        @a_past_date = 15.days.ago.strftime("%Y-%m-%d")
        @right_now = Time.zone.today.strftime("%Y-%m-%d")
        @a_future_date = 1.year.from_now.strftime("%Y-%m-%d")
      end

      it "shows that it is not planted yet" do
        fill_autocomplete "crop", with: "mai"
        select_from_autocomplete "maize"
        within "form#new_planting" do
          choose 'Garden'
          fill_in "When", with: @a_future_date
          fill_in "How many?", with: 42
          select "cutting", from: "Planted from"
          select "semi-shade", from: "Sun or shade?"
          fill_in "Tell us more about it", with: "It's rad."
          click_button "Save"
        end

        expect(page).to have_content "planting was successfully created"
        expect(page).to have_content "0%"
      end

      it "shows that days before maturity is unknown" do
        fill_autocomplete "crop", with: "mai"
        select_from_autocomplete "maize"
        within "form#new_planting" do
          choose 'Garden'
          fill_in "When", with: @a_past_date
          fill_in "How many?", with: 42
          select "cutting", from: "Planted from"
          select "semi-shade", from: "Sun or shade?"
          fill_in "Tell us more about it", with: "It's rad."
          click_button "Save"
        end

        expect(page).to have_content "planting was successfully created"
        expect(page).not_to have_content "Finished"
        expect(page).not_to have_content "Finishes"
      end

      it "shows that planting is in progress" do
        fill_autocomplete "crop", with: "mai"
        select_from_autocomplete "maize"
        within "form#new_planting" do
          choose 'Garden'
          fill_in "When", with: @right_now
          fill_in "How many?", with: 42
          select "cutting", from: "Planted from"
          select "semi-shade", from: "Sun or shade?"
          fill_in "When?", with: '2013-03-10'
          fill_in "Tell us more about it", with: "It's rad."
          fill_in "Finished date", with: @a_future_date
          click_button "Save"
        end

        expect(page).to have_content "planting was successfully created"
        expect(page).not_to have_content "0%"
        expect(page).not_to have_content "Finish expected"
        expect(page).not_to have_content "Finishes"
      end

      it "shows that planting is 100% complete (no date specified)" do
        fill_autocomplete "crop", with: "mai"
        select_from_autocomplete "maize"
        within "form#new_planting" do
          choose 'Garden'
          fill_in "When", with: @right_now
          fill_in "How many?", with: 42
          select "cutting", from: "Planted from"
          select "semi-shade", from: "Sun or shade?"
          fill_in "Tell us more about it", with: "It's rad."
          check "Mark as finished"
          click_button "Save"
        end

        expect(page).to have_content "planting was successfully created"
        expect(page).to have_content "Finished"
      end

      it "shows that planting is 100% complete (date specified)" do
        fill_autocomplete "crop", with: "mai"
        select_from_autocomplete "maize"
        within "form#new_planting" do
          choose 'Garden'
          fill_in "When", with: @a_past_date
          fill_in "How many?", with: 42
          select "cutting", from: "Planted from"
          select "semi-shade", from: "Sun or shade?"
          choose 'Garden'
          fill_in "Tell us more about it", with: "It's rad."
          fill_in "Finished date", with: @right_now
          click_button "Save"
        end

        expect(page).to have_content "planting was successfully created"
        expect(page).to have_content "Finished"
      end
    end

    it "Planting from crop page" do
      visit crop_path(maize)
      click_link "Add to my garden"
      click_link "Orchard"
      expect(page).to have_content "planting was successfully created"
      expect(page).to have_content "maize"
    end

    it "Editing a planting to add details" do
      visit planting_path(planting)
      click_link 'Actions'
      click_link "Edit"
      fill_in "Tell us more about it", with: "Some extra notes"
      click_button "Save"
      expect(page).to have_content "planting was successfully updated"
    end

    it "Editing a planting to fill in the finished date" do
      visit planting_path(planting)
      expect(page).not_to have_content "Finishes"
      # click_link(id: 'planting-actions-button')
      click_link 'Actions'
      click_link "Edit"
      check "finished"
      fill_in "Finished date", with: "2015-06-25"
      click_button "Save"
      expect(page).to have_content "planting was successfully updated"
      expect(page).to have_content "Finished"
    end

    it "Marking a planting as finished" do
      fill_autocomplete "crop", with: "mai"
      select_from_autocomplete "maize"
      choose(member.gardens.first.name)
      within "form#new_planting" do
        fill_in "When?", with: "2014-07-01"
        check "Mark as finished"
        fill_in "Finished date", with: "2014-08-30"
        uncheck 'Mark as finished'
      end

      # Javascript removes the finished at date when the
      # planting is marked unfinished.
      expect(find("#planting_finished_at").value).to eq("")

      within "form#new_planting" do
        check 'Mark as finished'
      end

      # The finished at date was cached in Javascript in
      # case the user clicks unfinished accidentally.
      expect(find("#planting_finished_at").value).to eq("2014-08-30")

      within "form#new_planting" do
        click_button "Save"
      end
      expect(page).to have_content "planting was successfully created"
      expect(page).to have_content "Finished"
      expect(page).to have_content "Aug 2014"

      # ensure we've indexed in elastic search
      planting.reindex(refresh: true)

      # shouldn't be on the page
      visit plantings_path
      expect(page).not_to have_content "maize"

      # show all plantings to see this finished planting
      visit plantings_path(all: 1)
      expect(page).to have_content "maize"
    end

    describe "Marking a planting as finished without a date" do
      before do
        fill_autocomplete "crop", with: "mai"
        select_from_autocomplete "maize"
        within "form#new_planting" do
          choose member.gardens.first.name
          check "Mark as finished"
          click_button "Save"
        end
      end

      it { expect(page).to have_content "planting was successfully created" }
      it { expect(page).to have_content "Finished" }
    end

    describe "Planting sunniness" do
      before "shows the a sunny image" do
        fill_autocomplete "crop", with: "mai"
        select_from_autocomplete "maize"
        within "form#new_planting" do
          fill_in "When", with: "2015-10-15"
          fill_in "How many?", with: 42
          select "cutting", from: "Planted from"
          select "sun", from: "Sun or shade?"
          fill_in "Tell us more about it", with: "It's rad."
          check "Mark as finished"
          click_button "Save"
        end

        it { expect(page).to have_css("img[alt='sun']") }
      end
    end

    describe "Marking a planting as finished from the show page" do
      let(:path) { planting_path(planting) }
      let(:link_text) { "Mark as finished" }

      it_behaves_like "append date"
    end
  end
end
