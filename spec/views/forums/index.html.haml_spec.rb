require 'spec_helper'

describe "forums/index" do
  before(:each) do
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
      rendered.should contain @post.subject
      rendered.should contain "less than a minute ago"
    end

    it "displays comment count" do
      assert_select "td", :text => "1"
    end

  end
end
