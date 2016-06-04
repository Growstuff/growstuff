## DEPRECATION NOTICE: Do not add new tests to this file!
##
## View and controller tests are deprecated in the Growstuff project. 
## We no longer write new view and controller tests, but instead write 
## feature tests (in spec/features) using Capybara (https://github.com/jnicklas/capybara). 
## These test the full stack, behaving as a browser, and require less complicated setup 
## to run. Please feel free to delete old view/controller tests as they are reimplemented 
## in feature tests. 
##
## If you submit a pull request containing new view or controller tests, it will not be 
## merged.





require 'rails_helper'

describe "harvests/index" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @member   = FactoryGirl.create(:member)
    @tomato = FactoryGirl.create(:tomato)
    @maize  = FactoryGirl.create(:maize)
    @pp = FactoryGirl.create(:plant_part)
    page = 1
    per_page = 2
    total_entries = 2
    harvests = WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
      pager.replace([
        FactoryGirl.create(:harvest,
          crop: @tomato,
          owner: @member
        ),
        FactoryGirl.create(:harvest,
          crop: @maize,
          plant_part: @pp,
          owner: @member
        )
      ])
    end
    assign(:harvests, harvests)
    render
  end

  it "provides data links" do
    render
    rendered.should have_content "The data on this page is available in the following formats:"
    assert_select "a", href: harvests_path(format: 'csv')
    assert_select "a", href: harvests_path(format: 'json')
  end

  it "displays member's name in title" do
    assign(:owner, @member)
    render
    view.content_for(:title).should have_content @member.login_name
  end

  it "displays crop's name in title" do
    assign(:crop, @tomato)
    render
    view.content_for(:title).should have_content @tomato.name
  end

end
