require 'spec_helper'

describe "updates/show" do
  before(:each) do
    @user = FactoryGirl.create(:user)
  end

  it "renders the post" do
    @update = assign(:update,
      FactoryGirl.create(:update, :user => @user))
    render
    # show the name of the member who posted the update
    rendered.should match(/user1/)
    # Subject goes in title
    rendered.should match(/This is some text./)
    # shouldn't show the subject on a single post page
    # (it appears in the title/h1 via the layout, not via this view)
    rendered.should_not match(/An Update/)
  end

  it "should parse markdown into html" do
    @update = assign(:update,
      FactoryGirl.create(:markdown_update, :user => @user))
    render
    assert_select "strong", "strong"
  end

  it "shouldn't let html through in body" do
    @update = assign(:update,
      FactoryGirl.create(:html_update, :user => @user))
    render
    rendered.should match(/EVIL/)
    rendered.should_not match(/a href="http:\/\/evil.com"/)
  end

end
