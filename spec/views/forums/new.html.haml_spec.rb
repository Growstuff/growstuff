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

describe "forums/new" do
  before(:each) do
    @forum = assign(:forum, FactoryGirl.create(:forum))
    render
  end

  it "renders new forum form" do
    assert_select "form", action: forums_path, method: "post" do
      assert_select "input#forum_name", name: "forum[name]"
      assert_select "textarea#forum_description", name: "forum[description]"
      assert_select "select#forum_owner_id", name: "forum[owner_id]"
    end
  end
end
