require 'spec_helper'

describe "posts/show" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @author = FactoryGirl.create(:member)
  end

  it "renders the post" do
    @post = assign(:post,
      FactoryGirl.create(:post, :author => @author))
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
      FactoryGirl.create(:markdown_post, :author => @author))
    render
    assert_select "strong", "strong"
  end

  it "shouldn't let html through in body" do
    @post = assign(:post,
      FactoryGirl.create(:html_post, :author => @author))
    render
    rendered.should match(/EVIL/)
    rendered.should_not match(/a href="http:\/\/evil.com"/)
  end

  it "shows comments" do
    @post = assign(:post,
      FactoryGirl.create(:html_post, :author => @author))
    @comment = FactoryGirl.create(:comment, :post => @post)
    render
    rendered.should contain @comment.body
  end

  context "forum post" do
    it "shows forum name" do
      @post = assign(:post,
        FactoryGirl.create(:forum_post, :author => @author))
      render
      rendered.should contain "in #{@post.forum.name}"
    end
  end

  context "signed in" do
    before(:each) do
      sign_in @author
      controller.stub(:current_user) { @author }
      @post = assign(:post,
        FactoryGirl.create(:post, :author => @author))
      render
    end

    it 'shows a comment button' do
      assert_select "a[href=#{new_comment_path(:post_id => @post.id)}]", "Comment"
    end

  end

end
