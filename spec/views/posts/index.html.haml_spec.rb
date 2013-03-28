require 'spec_helper'

describe "posts/index" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @author = FactoryGirl.create(:member)
    page = 1
    per_page = 2
    total_entries = 2
    posts = WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
      pager.replace([
        FactoryGirl.create(:post, :author => @author),
        FactoryGirl.create(:post, :author => @author)
      ])
    end
    assign(:posts, posts)
    render
  end

  it "renders a list of posts" do
    assert_select "div.post", :count => 2
    assert_select "h3", :text => "A Post".to_s, :count => 2
    assert_select "div.post-body",
      :text => "This is some text.".to_s, :count => 2
  end

  it "contains two gravatar icons" do
    assert_select "img", :src => /gravatar\.com\/avatar/, :count => 2
  end
end
