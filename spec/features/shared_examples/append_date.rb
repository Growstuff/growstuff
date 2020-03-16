# frozen_string_literal: true

shared_examples "append date" do
  let(:this_month) { Time.zone.today.strftime("%b") }
  let(:this_year) { Time.zone.today.year }

  before { visit path }

  describe "Selecting a date with datepicker" do
    before do
      click_link 'Actions'
      click_link link_text
      within "div.datepicker" do
        expect(page).to have_content this_month.to_s
        find(".datepicker-days td.day", text: "21").click
      end
    end
    it { expect(page).to have_content "Finished" }
    it { expect(page).to have_content "#{this_month} #{this_year}" }
  end

  describe "Confirming without selecting date" do
    before do
      click_link 'Actions'
      click_link link_text
      click_link "Confirm without date"
    end
    it { expect(page).to have_content("Finished") }
  end
end
