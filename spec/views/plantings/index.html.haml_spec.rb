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

describe "plantings/index" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @member   = FactoryGirl.create(:member)
    @garden = FactoryGirl.create(:garden, owner: @member)
    @tomato = FactoryGirl.create(:tomato)
    @maize  = FactoryGirl.create(:maize)
    page = 1
    per_page = 3
    total_entries = 3
    plantings = WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
      pager.replace([
        FactoryGirl.create(:planting,
          garden: @garden,
          crop: @tomato,
          owner: @member
        ),
        FactoryGirl.create(:planting,
          garden: @garden,
          crop: @maize,
          description: '',
          planted_at: Time.local(2013, 1, 13)
        ),
        FactoryGirl.create(:planting,
          garden: @garden,
          crop: @tomato,
          planted_at: Time.local(2013, 1, 13),
          finished_at: Time.local(2013, 1, 20),
          finished: true
        )
      ])
    end
    assign(:plantings, plantings)
    render
  end

  it "renders a list of plantings" do
    rendered.should have_content @tomato.name
    rendered.should have_content @maize.name
    rendered.should have_content @member.login_name
    rendered.should have_content @garden.name
  end

  it "displays planting time" do
    rendered.should have_content 'January 13, 2013'
  end

  it "displays finished time" do
    rendered.should have_content 'January 20, 2013'
  end

  it "provides data links" do
    render
    rendered.should have_content "The data on this page is available in the following formats:"
    assert_select "a", href: plantings_path(format: 'csv')
    assert_select "a", href: plantings_path(format: 'json')
    assert_select "a", href: plantings_path(format: 'rss')
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
