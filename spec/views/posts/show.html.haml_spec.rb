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
    rendered.should match(/member1/)
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

end
