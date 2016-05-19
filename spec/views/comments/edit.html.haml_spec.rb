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

describe "comments/edit" do
  before(:each) do
    controller.stub(:current_user) { nil }
    assign(:comment, FactoryGirl.create(:comment))
  end

  it "renders the edit comment form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", action: comments_path(@comment), method: "post" do
      assert_select "textarea#comment_body", name: "comment[body]"
    end
  end
end
