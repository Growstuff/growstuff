require 'spec_helper'

describe "posts/new" do
  before(:each) do
    @author = FactoryGirl.create(:member)
    assign(:post, FactoryGirl.create(:post, :author => @author))
    assign(:forum, Forum.new)
    sign_in @author
    controller.stub(:current_user) { @author }
  end

  it "renders new post form" do
    render
    assert_select "form", :action => posts_path, :method => "post" do
      assert_select "input#post_subject", :name => "post[subject]"
      assert_select "textarea#post_body", :name => "post[body]"
    end
  end

  it 'no hidden forum field' do
    assert_select "input#post_forum_id[type=hidden]", false
  end

  it 'no forum mentioned' do
    rendered.should_not contain "This post will be posted in the forum"
  end

  context "forum specified" do
    before(:each) do
      @forum = assign(:forum, FactoryGirl.create(:forum))
      assign(:post, FactoryGirl.create(:post, :forum => @forum))
      render
    end

    it 'creates a hidden field' do
      assert_select "input#post_forum_id[type=hidden][value=#{@forum.id}]"
    end

    it 'tells the user what forum it will be posted in' do
      rendered.should contain "This post will be posted in the forum #{@forum.name}"
    end
  end

end
