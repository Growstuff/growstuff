require 'spec_helper'

describe "forums/show" do
  before(:each) do
    @forum = assign(:forum, FactoryGirl.create(:forum))
    render
  end

  it "renders attributes" do
    rendered.should contain @forum.description
    rendered.should contain @forum.owner.to_s
  end

  it 'links to new post with the forum id' do
    assert_select "a[href=#{new_post_path(:forum_id => @forum.id)}]"
  end
end
