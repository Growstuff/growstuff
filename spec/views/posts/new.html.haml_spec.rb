require 'rails_helper'

describe "posts/new" do
  before(:each) do
    @author = FactoryBot.create(:member)
    assign(:post, FactoryBot.create(:post, author: @author))
    # assign(:forum, Forum.new)
    sign_in @author
    controller.stub(:current_user) { @author }
  end

  it "renders new post form" do
    render
    assert_select "form", action: posts_path, method: "post" do
      assert_select "input#post_subject", name: "post[subject]"
      assert_select "textarea#post_body", name: "post[body]"
    end
  end

  it 'no hidden forum field' do
    render
    assert_select "input#post_forum_id[type=hidden]", false
  end

  it 'no forum mentioned' do
    render
    rendered.should_not have_content "This post will be posted in the forum"
  end

  it "asks what's going on in your garden" do
    render
    rendered.should have_content "What's going on in your food garden?"
  end

  context "forum specified" do
    before(:each) do
      @forum = assign(:forum, FactoryBot.create(:forum))
      assign(:post, FactoryBot.create(:post, forum: @forum))
      render
    end

    it 'creates a hidden field' do
      assert_select "input#post_forum_id[type='hidden'][value='#{@forum.id}']"
    end

    it 'tells the user what forum it will be posted in' do
      rendered.should have_content "This post will be posted in the forum #{@forum.name}"
    end

    it "asks what's going on generally" do
      render
      rendered.should_not have_content "What's going on in your food garden?"
      rendered.should have_content "What's up?"
    end
  end

  it 'shows markdown help' do
    render
    rendered.should have_content 'Markdown'
  end
end
