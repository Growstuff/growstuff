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

describe "comments/index" do
  before(:each) do
    controller.stub(:current_user) { nil }
    page = 1
    per_page = 2
    total_entries = 2
    comments = WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
      pager.replace([
        FactoryGirl.create(:comment),
        FactoryGirl.create(:comment, body: 'ROFL')
      ])
    end
    assign(:comments, comments)
    render
  end

  it "renders a list of comments" do
    render
    rendered.should have_content 'OMG LOL'
    rendered.should have_content 'ROFL'
  end

  it "contains an RSS feed link" do
    assert_select "a", href: comments_path(format: 'rss')
  end
end
