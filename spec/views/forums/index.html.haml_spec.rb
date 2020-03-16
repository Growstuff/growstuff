# frozen_string_literal: true

require 'rails_helper'

describe "forums/index" do
  let(:admin) { FactoryBot.create(:admin_member) }
  let(:forum1) { FactoryBot.create(:forum) }
  let(:forum2) { FactoryBot.create(:forum) }
  before do
    controller.stub(:current_user) { admin }
    assign(:forums, [forum1, forum2])
  end

  it "renders a list of forums" do
    render
    assert_select "h2", text: forum1.name, count: 2
  end

  it "doesn't display posts for empty forums" do
    render
    assert_select "table", false
  end

  context "posts" do
    let!(:post) { FactoryBot.create(:forum_post, forum: forum1) }
    let!(:comment) { FactoryBot.create(:comment, post: post) }
    before { render }

    describe "displays posts" do
      it { assert_select "table" }

      # only check for the first 20 chars, because it can be truncated when long
      it { expect(rendered).to have_content post.subject[0..20] }

      it { expect(rendered).to have_content Time.zone.today.to_s(:short) }
    end

    it "displays comment count" do
      assert_select "td", text: "1"
    end
  end
end
