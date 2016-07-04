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

describe "posts/show" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @author = FactoryGirl.create(:member)
  end

  it "renders the post" do
    @post = assign(:post,
      FactoryGirl.create(:post, author: @author))
    render
    # show the name of the member who posted the post
    rendered.should match(/member\d+/)
    # Subject goes in title
    rendered.should match(/This is some text./)
    # shouldn't show the subject on a single post page
    # (it appears in the title/h1 via the layout, not via this view)
    rendered.should_not match(/An Update/)
  end

  it "should parse markdown into html" do
    @post = assign(:post,
      FactoryGirl.create(:markdown_post, author: @author))
    render
    assert_select "strong", "strong"
  end

  it "shouldn't let html through in body" do
    @post = assign(:post,
      FactoryGirl.create(:html_post, author: @author))
    render
    rendered.should match(/EVIL/)
    rendered.should_not match(/a href="http:\/\/evil.com"/)
  end

  it 'has an anchor to the comments' do
    @post = assign(:post,
                   FactoryGirl.create(:post, author: @author))
    render
    assert_select 'a[name=comments]'
  end

  context "when there is one comment" do
    before(:each) do
      @post = assign(:post,
                     FactoryGirl.create(:html_post, author: @author))
      @comment = FactoryGirl.create(:comment, post: @post)
      @comments = @post.comments
      render
    end

    it 'shows comment count only 1' do
      assert_select "div.post_comments", false
    end

    it "shows comments" do
      rendered.should have_content @comment.body
    end

    it 'has an anchor to the comments' do
      assert_select 'a[name=comments]'
    end
  end

  context "when there is more than one comment" do
    before(:each) do
      @post = assign(:post,
                     FactoryGirl.create(:html_post, author: @author))
      @comment1 = FactoryGirl.create(:comment, post: @post, body: "F1rst!!!",
                                    created_at: Date.new(2010, 5, 17))
      @comment3 = FactoryGirl.create(:comment, post: @post, body: "Th1rd!!!",
                                    created_at: Date.new(2012, 5, 17))
      @comment4 = FactoryGirl.create(:comment, post: @post, body: "F0urth!!!")
      @comment2 = FactoryGirl.create(:comment, post: @post, body: "S3c0nd!!1!",
                                    created_at: Date.new(2011, 5, 17))
      @comments = @post.comments
      render
    end

    it "shows the oldest comments first" do
      rendered.should have_content /#{@comment1.body}.*#{@comment2.body}.*#{@comment3.body}.*#{@comment4.body}/m
    end
  end

  context "forum post" do
    it "shows forum name" do
      @post = assign(:post,
        FactoryGirl.create(:forum_post, author: @author))
      render
      rendered.should have_content "in #{@post.forum.name}"
    end
  end
  
  context "signed in" do
    before(:each) do
      sign_in @author
      controller.stub(:current_user) { @author }
      @post = assign(:post,
        FactoryGirl.create(:post, author: @author))
      render
    end

    it 'shows a comment button' do
      assert_select "a", {href: new_comment_path(post_id: @post.id)}, "Comment"
    end 

  end

end
