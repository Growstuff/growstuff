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

describe "forums/show" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @forum = assign(:forum, FactoryGirl.create(:forum))
  end

  it "renders attributes" do
    render
    rendered.should have_content "Everything about permaculture"
    rendered.should have_content @forum.owner.to_s
  end

  it "parses markdown description into html" do
    render
    assert_select "em", "Everything"
  end

  it 'links to new post with the forum id' do
    render
    assert_select "a[href='#{new_post_path(forum_id: @forum.id)}']"
  end

  it 'has no posts' do
    render
    rendered.should have_content "No posts yet."
  end

  it 'shows posts' do
    @post = FactoryGirl.create(:post, forum: @forum)
    render
    assert_select "table"
    rendered.should have_content @post.subject
    rendered.should have_content @post.author.to_s
  end
end
