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

describe "forums/index" do
  before(:each) do
    @admin = FactoryGirl.create(:admin_member)
    controller.stub(:current_user) { @admin }
    @forum1 = FactoryGirl.create(:forum)
    @forum2 = FactoryGirl.create(:forum)
    assign(:forums, [ @forum1, @forum2 ])
  end

  it "renders a list of forums" do
    render
    assert_select "h2", :text => @forum1.name, :count => 2
  end

  it "doesn't display posts for empty forums" do
    render
    assert_select "table", false
  end

  context "posts" do
    before(:each) do
      @post = FactoryGirl.create(:forum_post, :forum => @forum1)
      @comment = FactoryGirl.create(:comment, :post => @post)
      render
    end

    it "displays posts" do
      assert_select "table"
      rendered.should have_content @post.subject
      rendered.should have_content Time.zone.today.to_s(:short)
    end

    it "displays comment count" do
      assert_select "td", :text => "1"
    end

  end
end
