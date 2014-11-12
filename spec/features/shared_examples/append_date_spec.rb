shared_examples "append date" do

  scenario "Selecting a date with datepicker" do
    this_month = Date.today.strftime("%B")
    this_year  = Date.today.strftime("%Y")
    visit path
    click_link link_text
    within "div.datepicker" do
      expect(page).to have_content "#{this_month}"
      page.find(".datepicker-days td.day", text: "21").click
    end
    expect(page).to have_content "Finished: #{this_month} 21, #{this_year}"
  end

  scenario "Confirming without selecting date" do
    visit path
    click_link link_text
    click_link "Confirm without date"
    expect(page).to have_content("Finished: Yes (no date specified) ")
  end

end