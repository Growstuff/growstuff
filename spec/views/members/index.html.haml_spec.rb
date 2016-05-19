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

describe "members/index" do
  before(:each) do
    controller.stub(:current_user) { nil }
    page = 1
    per_page = 2
    total_entries = 2
    @member = FactoryGirl.create(:london_member)
    members = WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
      pager.replace([ @member, @member ])
    end
    assign(:members, members)
    render
  end

  it "contains two gravatar icons" do
    assert_select "img", src: /gravatar\.com\/avatar/, count: 2
  end

  it 'contains member locations' do
    rendered.should have_content @member.location
  end

end
