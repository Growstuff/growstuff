require 'spec_helper'

describe "forums/show" do
  before(:each) do
    @forum = assign(:forum, FactoryGirl.create(:forum))
    render
  end

  it "renders attributes" do
    rendered.should contain "Everything about permaculture"
    rendered.should contain @forum.owner.to_s
  end

  it "parses markdown description into html" do
    assert_select "em", "Everything"
  end

  it 'links to new post with the forum id' do
    assert_select "a[href=#{new_post_path(:forum_id => @forum.id)}]"
  end
end
