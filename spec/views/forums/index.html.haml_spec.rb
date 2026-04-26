# frozen_string_literal: true

require 'rails_helper'

describe "forums/index" do
  let(:admin) { create(:admin_member) }
  let(:first_forum) { create(:forum) }
  let(:second_forum) { create(:forum) }

  before do
    controller.stub(:current_user) { admin }
    assign(:forums, [first_forum, second_forum])
  end

  it "renders a list of forums" do
    render
    assert_select "h2", text: first_forum.name, count: 2
  end

  it "doesn't display posts for empty forums" do
    render
    assert_select "table", false
  end

  context "posts" do
    let!(:post) { create(:forum_post, forum: first_forum) }
    let!(:comment) { create(:comment, commentable: post) }

    before { render }

    describe "displays posts" do
      it { assert_select "table" }

      # only check for the first 20 chars, because it can be truncated when long
      it { expect(rendered).to have_content post.subject[0..20] }

      it { expect(rendered).to have_content Time.zone.today.to_fs(:short) }
    end

    it "displays comment count" do
      assert_select "td", text: "1"
    end
  end
end
