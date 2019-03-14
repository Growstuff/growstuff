# frozen_string_literal: true

require 'rails_helper'

describe "posts/new" do
  let(:author) { FactoryBot.create(:member) }

  before do
    assign(:post, FactoryBot.create(:post, author: author))
    # assign(:forum, Forum.new)
    sign_in author
    controller.stub(:current_user) { author }
    render
  end

  it "renders new post form" do
    assert_select "form", action: posts_path, method: "post" do
      assert_select "input#post_subject", name: "post[subject]"
      assert_select "textarea#post_body", name: "post[body]"
    end
  end

  it 'no hidden forum field' do
    assert_select "input#post_forum_id[type=hidden]", false
  end

  it 'no forum mentioned' do
    expect(rendered).not_to have_content "This post will be posted in the forum"
  end

  it "asks what's going on in your garden" do
    expect(rendered).to have_content "What's going on in your food garden?"
  end

  it 'shows markdown help' do
    expect(rendered).to have_content 'Markdown'
  end

  context "forum specified" do
    let(:forum) { FactoryBot.create(:forum) }

    before do
      assign(:forum, forum)
      assign(:post, FactoryBot.create(:post, forum: forum))
      render
    end

    it 'creates a hidden field' do
      assert_select "input#post_forum_id[type='hidden'][value='#{forum.id}']"
    end

    it 'tells the user what forum it will be posted in' do
      expect(rendered).to have_content "This post will be posted in the forum #{forum.name}"
    end
    it { expect(rendered).to have_link forum.name }

    describe "asks what's going on generally" do
      it { expect(rendered).to have_content "What's going on in your food garden?" }
      it { expect(rendered).to have_content "What's up?" }
    end
  end
end
