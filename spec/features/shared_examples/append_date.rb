shared_examples "append date" do
  let(:this_month) { Time.zone.today.strftime("%B") }
  let(:this_year) { Time.zone.today.strftime("%Y") }

  background { visit path }

  scenario "Selecting a date with datepicker" do
    click_link link_text
    within "div.datepicker" do
      expect(page).to have_content this_month.to_s
      find(".datepicker-days td.day", text: "21").click
    end
    expect(page).to have_content "Finished: #{this_month} 21, #{this_year}"
  end

  scenario "Confirming without selecting date" do
    click_link link_text
    click_link "Confirm without date"
    expect(page).to have_content("Finished: Yes (no date specified) ")
  end
end
