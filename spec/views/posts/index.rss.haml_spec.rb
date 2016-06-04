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

describe 'posts/index.rss.haml', type: "view" do
  before(:each) do
    controller.stub(:current_user) { nil }
    author = FactoryGirl.create(:member)
    @post1 = FactoryGirl.create(:post, id: 1, author: author)
    @post2 = FactoryGirl.create(:post, id: 2, author: author)
    assign(:posts, [@post1, @post2])
    render
  end

  it 'shows RSS feed title' do
    rendered.should have_content "Recent posts from all members"
  end

  it 'shows content of posts' do
    rendered.should have_content "This is some text."
  end

  it 'gives the author in the item title' do
    rendered.should have_content "#{@post1.subject} by #{@post1.author}"
  end

end
