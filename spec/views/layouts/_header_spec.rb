require 'rails_helper'

describe 'layouts/_header.html.haml', type: "view" do
  context "when not logged in" do
    before(:each) do
      controller.stub(:current_user) { nil }
      render
    end

    it 'shows the brand logo in the navbar' do
      assert_select("a.navbar-brand img[src]", href: root_path)
    end

    it 'should have signup/signin links' do
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
      assert_select("form[action='#{crops_search_path}']")
      assert_select("input#term")
    end
  end

  context "logged in" do
    before(:each) do
      @member = FactoryBot.create(:member)
      sign_in @member
      controller.stub(:current_user) { @member }
      render
    end

    context "login name" do
      it 'should have member login name' do
        rendered.should have_content @member.login_name.to_s
      end
      it "should show link to member's gardens" do
        assert_select("a[href='#{gardens_by_owner_path(owner: @member.slug)}']", "Gardens")
      end
      it "should show link to member's plantings" do
        assert_select("a[href='#{plantings_by_owner_path(owner: @member.slug)}']", "Plantings")
      end
      it "should show link to member's seeds" do
        assert_select("a[href='#{seeds_by_owner_path(owner: @member.slug)}']", "Seeds")
      end
      it "should show link to member's posts" do
        assert_select("a[href='#{posts_by_author_path(author: @member.slug)}']", "Posts")
      end
    end

    it 'should show signout link' do
      rendered.should have_content 'Sign out'
    end

    it 'should show inbox link' do
      rendered.should have_content 'Inbox'
      rendered.should_not match(/Inbox \(\d+\)/)
    end

    context 'has notifications' do
      it 'should show inbox count' do
        FactoryBot.create(:notification, recipient: @member)
        render
        rendered.should have_content 'Inbox (1)'
      end
    end
  end
end
