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
      rendered.should have_content 'Sign up'
      rendered.should have_content 'Sign in'
    end

    it 'has a Crops link' do
      rendered.should have_content "Crops"
    end

    it 'has a Seeds link' do
      rendered.should have_content "Seeds"
    end

    it 'has a Places link' do
      rendered.should have_content "Community Map"
    end

    it 'has a Community section' do
      rendered.should have_content "Community"
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

    it 'has a crop search' do
      assert_select("form[action='#{search_crops_path}']")
      assert_select("input#term")
    end
  end

  context "logged in" do
    before do
      @member = FactoryBot.create(:member)
      sign_in @member
      controller.stub(:current_user) { @member }
      render
    end

    context "login name" do
      it 'has member login name' do
        rendered.should have_content @member.login_name.to_s
      end
      it "shows link to member's gardens" do
        assert_select("a[href='#{member_gardens_path(@member)}']", "Gardens")
      end
      it "shows link to member's plantings" do
        assert_select("a[href='#{member_plantings_path(@member)}']", "Plantings")
      end
      it "shows link to member's seeds" do
        assert_select("a[href='#{member_seeds_path(@member)}']", "Seeds")
      end
      it "shows link to member's posts" do
        assert_select("a[href='#{member_posts_path(@member)}']", "Posts")
      end
    end

    it 'shows signout link' do
      rendered.should have_content 'Sign out'
    end

    it 'shows inbox link' do
      rendered.should have_content 'Inbox'
      rendered.should_not match(/Inbox \d+/)
    end

    context 'has notifications' do
      it 'shows inbox count' do
        FactoryBot.create(:notification, recipient: @member)
        render
        rendered.should have_content 'Inbox 1'
      end
    end
  end
end
