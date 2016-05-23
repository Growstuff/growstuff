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

describe 'comments/index.rss.haml' do
  before(:each) do
    controller.stub(:current_user) { nil }
    @author = FactoryGirl.create(:member)
    @post = FactoryGirl.create(:post)
    assign(:comments, [
      FactoryGirl.create(:comment, author: @author, post: @post),
      FactoryGirl.create(:comment, author: @author, post: @post)
    ])
    render
  end

  it 'shows RSS feed title' do
    rendered.should have_content "Recent comments on all posts"
  end

  it 'shows item title' do
    rendered.should have_content "Comment by #{@author.login_name}"
  end

  it 'escapes html for link to post' do
    # it's then unescaped by 'render' so we don't actually look for &lt;
    rendered.should have_content '<a href='
  end

  it 'shows content of comments' do
    rendered.should have_content "OMG LOL"
  end

end
