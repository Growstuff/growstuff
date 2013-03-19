require 'spec_helper'

describe "posts/index" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @author = FactoryGirl.create(:member)
    # We use create (= build+save) to generate slugs and hence paths for posts
    @post1 = FactoryGirl.create(:post, :author => @author)
    @post2 = FactoryGirl.create(:post, :author => @author)
    assign(:posts, [@post1, @post2])
    render
  end

  it "renders a list of posts" do
    assert_select "div.post", :count => 2
    assert_select "h3", :text => "A Post".to_s, :count => 2
    assert_select "div.post-body",
      :text => "This is some text.".to_s, :count => 2
  end

  it "counts the number of posts" do
    rendered.should contain "Displaying 2 posts"
  end

  it "contains two gravatar icons" do
    assert_select "img", :src => /gravatar\.com\/avatar/, :count => 2
  end
end
