# frozen_string_literal: true

require 'rails_helper'

describe "posts/edit" do
  before do
    controller.stub(:current_user) { nil }
    @author = create(:member)
    @post = assign(:post, create(:post, author: @author))
  end

  context "logged in" do
    before do
      sign_in @author
      render
    end

    it "renders the edit post form" do
      assert_select "form", action: posts_path(@post), method: "post" do
        assert_select "input#post_subject", name: "post[subject]"
        assert_select "textarea#post_body", name: "post[body]"
      end
    end

    it 'no hidden forum field' do
      assert_select "input#post_forum_id[type=hidden]", false
    end

    it 'no forum mentioned' do
      expect(rendered).to have_no_content "This post will be posted in the forum"
    end

    context "forum specified" do
      before do
        @forum = assign(:forum, create(:forum))
        assign(:post, create(:post,
                             forum:  @forum,
                             author: @author))
        render
      end

      it 'creates a hidden field' do
        assert_select "input#post_forum_id[type='hidden'][value='#{@forum.id}']"
      end

      it 'tells the user what forum it will be posted in' do
        expect(rendered).to have_content "This post will be posted in the forum #{@forum.name}"
      end
    end
  end
end
