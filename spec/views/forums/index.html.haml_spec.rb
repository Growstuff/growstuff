require 'rails_helper'

describe "forums/index" do
  before(:each) do
    @admin = FactoryBot.create(:admin_member)
    controller.stub(:current_user) { @admin }
    @forum1 = FactoryBot.create(:forum)
    @forum2 = FactoryBot.create(:forum)
    assign(:forums, [@forum1, @forum2])
  end

  it "renders a list of forums" do
    render
    assert_select "h2", text: @forum1.name, count: 2
  end

  it "doesn't display posts for empty forums" do
    render
    assert_select "table", false
  end

  context "posts" do
    before(:each) do
      @post = FactoryBot.create(:forum_post, forum: @forum1)
      @comment = FactoryBot.create(:comment, post: @post)
      render
    end

    it "displays posts" do
      assert_select "table"
      rendered.should have_content @post.subject
      rendered.should have_content Time.zone.today.to_s(:short)
    end

    it "displays comment count" do
      assert_select "td", text: "1"
    end
  end
end
