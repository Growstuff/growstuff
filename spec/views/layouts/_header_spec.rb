# frozen_string_literal: true

require 'rails_helper'

describe 'layouts/_header.html.haml', type: "view" do
  context "when not logged in" do
    before do
      controller.stub(:current_user) { nil }
      render
    end

    it 'shows the brand logo in the navbar' do
      assert_select("a.navbar-brand img[src]", href: root_path)
    end

    it 'has signup/signin links' do
      expect(rendered).to have_content 'Join free'
      expect(rendered).to have_content 'Sign in'
    end

    it 'has a Crops link' do
      expect(rendered).to have_content "Crops"
    end

    it 'has a Seeds link' do
      expect(rendered).to have_content "Seeds"
    end

    it 'has a Places link' do
      expect(rendered).to have_content "Community Map"
    end

    it 'has a Community section' do
      expect(rendered).to have_content "Community"
    end

    it 'links to members' do
      assert_select("a[href='#{members_path}']", 'Browse Members')
    end

    it 'links to posts' do
      assert_select("a[href='#{posts_path}']", 'Posts')
    end

    it 'links to forums' do
      assert_select("a[href='#{forums_path}']", 'Forums')
    end

    it 'marks the section you are in' do
      allow(view.request).to receive(:path).and_return('/crops/basil')
      render
      assert_select("a[aria-current='page']", text: 'Crops')
    end

    it 'marks nothing on the home page' do
      render
      assert_select("a[aria-current='page']", count: 0)
    end

    it 'has a crop search' do
      assert_select("form[action='#{search_crops_path}']")
      assert_select("input#term")
    end
  end

  context "logged in" do
    before do
      @member = create(:member)
      sign_in @member
      controller.stub(:current_user) { @member }
      render
    end

    context "login name" do
      it 'has member login name' do
        expect(rendered).to have_content @member.login_name.to_s
      end

      it "shows link to member's garden" do
        assert_select("a[href='#{member_gardens_path(@member, anchor: 'content')}']", "My garden")
      end

      it "shows a My plantings link for the drawer" do
        assert_select("a[href='#{member_plantings_path(@member)}']", "My plantings")
      end

      it "shows a My harvests link for the drawer" do
        assert_select("a[href='#{member_harvests_path(@member)}']", "My harvests")
      end

      it "shows a My seeds link for the drawer" do
        assert_select("a[href='#{member_seeds_path(@member)}']", "My seeds")
      end

      it "shows link to member's posts" do
        assert_select("a[href='#{member_posts_path(@member)}']", "Posts")
      end
    end

    context "when on the member's own pages" do
      before do
        allow(view.request).to receive(:path).and_return("/members/#{@member.slug}/activities")
        render
      end

      it 'does not mark Community' do
        assert_select("a.dropdown-toggle[aria-current='page']", count: 0)
      end
    end

    context "when on another member's page" do
      before do
        allow(view.request).to receive(:path).and_return('/members/someone-else')
        render
      end

      it 'marks Community' do
        assert_select("a.dropdown-toggle[aria-current='page']", text: /Community/)
      end
    end

    it 'shows signout link' do
      expect(rendered).to have_content 'Sign out'
    end

    it 'shows inbox link' do
      expect(rendered).to have_content 'Inbox'
      expect(rendered).not_to match(/Inbox \d+/)
    end
  end

  context 'logged in, has notifications' do
    before do
      @member = create(:member)
      create(:notification, recipient: @member)
      sign_in @member
      controller.stub(:current_user) { @member }
    end

    it 'shows inbox count' do
      render
      rendered.should have_content 'Inbox 1'
    end
  end
end
