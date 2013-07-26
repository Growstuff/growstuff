require 'spec_helper'

describe 'layouts/_header.html.haml', :type => "view" do
  context "when not logged in" do
    before(:each) do
      controller.stub(:current_user) { nil }
      render
    end

    it 'shows the title' do
      rendered.should contain Growstuff::Application.config.site_name
    end

    it 'should have signup/signin links' do
      rendered.should contain 'Sign up'
      rendered.should contain 'Sign in'
    end

    it 'has a Crops link' do
      rendered.should contain "Crops"
    end

    it 'has a Seeds link' do
      rendered.should contain "Seeds"
    end

    it 'has a Community section' do
      rendered.should contain "Community"
    end

    it 'links to members' do
      assert_select("a[href=#{members_path}]", 'Members')
    end

    it 'links to posts' do
      assert_select("a[href=#{posts_path}]", 'Posts')
    end

    it 'links to forums' do
      assert_select("a[href=#{forums_path}]", 'Forums')
    end

  end

  context "logged in" do

    before(:each) do
      @member = FactoryGirl.create(:member)
      sign_in @member
      controller.stub(:current_user) { @member }
      render
    end

    context "your stuff" do
      it 'should have a Your Stuff section' do
        rendered.should contain "Your Stuff"
      end
      it "should show link to member's profile" do
        assert_select("a[href=#{member_path(@member)}]", "Profile")
      end
      it "should show link to member's gardens" do
        assert_select("a[href=#{gardens_by_owner_path(:owner => @member.slug)}]", "Gardens")
      end
      it "should show link to member's plantings" do
        assert_select("a[href=#{plantings_by_owner_path(:owner => @member.slug)}]", "Plantings")
      end
      it "should show link to member's seeds" do
        assert_select("a[href=#{seeds_by_owner_path(:owner => @member.slug)}]", "Seeds")
      end
      it "should show link to member's posts" do
        assert_select("a[href=#{posts_by_author_path(:author => @member.slug)}]", "Posts")
      end
    end

    it 'should show login name' do
      rendered.should contain /member\d+/
    end

    it "should show settings link" do
      assert_select "a[href=/members/edit]", "Settings"
    end

    it "should show account link" do
      assert_select "a[href=#{orders_path}]", "Account"
    end

    it 'should show signout link' do
      rendered.should contain 'Sign out'
    end

    it 'should show inbox link' do
      rendered.should contain 'Inbox'
      rendered.should_not match(/Inbox \(\d+\)/)
    end

    context 'has notifications' do
      it 'should show inbox count' do
        FactoryGirl.create(:notification, :recipient => @member)
        render
        rendered.should contain 'Inbox (1)'
      end
    end

  end
end
