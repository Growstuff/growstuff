require "rails_helper"

RSpec.feature "User searches", :type => :feature do
	let(:member)   { FactoryGirl.create(:member, location: "Philippines") }
    let!(:maize)   { FactoryGirl.create(:maize) }
    let(:garden)   { FactoryGirl.create(:garden, owner: member) }
    let!(:seed1)    { FactoryGirl.create(:seed, owner: member) }
    let!(:planting){ FactoryGirl.create(:planting, garden: garden, owner: member, planted_at: Date.parse("2013-3-10")) }

	scenario "with a valid place" do
		visit places_path
		search_with("Philippines")
		expect(page).to have_content "members near Philippines"
		expect(page).to have_button "search_button"
		page.has_content?('placesmap')
		expect(page).to have_content "Nearby members"
		expect(page).to_not have_content "No results found"
	end

	scenario "with a blank search string" do
		visit places_path
		search_with("")
		expect(page).to have_content "Please enter a valid location"
		expect(page).to have_button "search_button"
		page.has_content?('placesmap')
	end

  	describe "Nearby plantings, seed, and members" do
	    before(:each) do
	      login_as(member)
	      visit places_path
		  search_with("Philippines")
	    end

	    it "should show that there are nearby seeds, plantings, and members" do
	      expect(page).to have_content "Nearby members"
      	  expect(page).to have_content "Seeds available for trade near Philippines"
      	  expect(page).to have_content "Recent plantings near Philippines"
      	  find_link("View all members").visible?
      	  find_link("View all seeds").visible?
      	  find_link("View all plantings").visible?
      	end

      	it "should go to members' index page" do
      	  click_link('View all members >>')
      	  current_path.should == members_path
      	end

      	it "should go to plantings' index page" do
      	  click_link('View all plantings >>')
      	  current_path.should == plantings_path
      	end

      	it "should go to seeds' index page" do
      	  click_link('View all seeds >>')
      	  current_path.should == seeds_path
      	end
	end

  	def search_with(search_string)
		fill_in "new_place", :with => search_string
		click_button "search_button"
	end
end