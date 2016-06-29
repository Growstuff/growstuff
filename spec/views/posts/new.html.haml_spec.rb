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

describe "posts/new" do
  before(:each) do
    @author = FactoryGirl.create(:member)
    assign(:post, FactoryGirl.create(:post, author: @author))
# assign(:forum, Forum.new)
    sign_in @author
    controller.stub(:current_user) { @author }
  end

  it "renders new post form" do
    render
    assert_select "form", action: posts_path, method: "post" do
      assert_select "input#post_subject", name: "post[subject]"
      assert_select "textarea#post_body", name: "post[body]"
    end
  end

  it 'no hidden forum field' do
    render
    assert_select "input#post_forum_id[type=hidden]", false
  end

  it 'no forum mentioned' do
    render
    rendered.should_not have_content "This post will be posted in the forum"
  end

  it "asks what's going on in your garden" do
    render
    rendered.should have_content "What's going on in your food garden?"
  end

  context "forum specified" do
    before(:each) do
      @forum = assign(:forum, FactoryGirl.create(:forum))
      assign(:post, FactoryGirl.create(:post, forum: @forum))
      render
    end

    it 'creates a hidden field' do
      assert_select "input#post_forum_id[type='hidden'][value='#{@forum.id}']"
    end

    it 'tells the user what forum it will be posted in' do
      rendered.should have_content "This post will be posted in the forum #{@forum.name}"
    end

    it "asks what's going on generally" do
      render
      rendered.should_not have_content "What's going on in your food garden?"
      rendered.should have_content "What's up?"
    end
  end

  it 'shows markdown help' do
    render
    rendered.should have_content 'Markdown'
  end

end
