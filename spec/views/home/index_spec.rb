require 'spec_helper'

describe 'home/index.html.haml', :type => "view" do
  context 'logged out' do
    before(:each) do
      @member = FactoryGirl.create(:geolocated_member)
      @member.updated_at = 2.days.ago
      @post = FactoryGirl.create(:post, :author => @member)
      @planting = FactoryGirl.create(:planting, :garden => @member.gardens.first)
      controller.stub(:current_user) { nil }
      assign(:interesting_members, [@member])
      assign(:plantings, [@planting])
      assign(:posts, [@post])
      render
    end

    it 'has description' do
      rendered.should contain 'is a community of food gardeners'
    end

    it 'show recent posts' do
      rendered.should contain @post.subject
    end

    it 'show recent plantings' do
      rendered.should contain @planting.crop_system_name
      rendered.should contain @planting.garden.name
    end

    it 'show interesting members' do
      rendered.should contain @member.login_name
      rendered.should contain @member.location
    end
  end

  context 'logged in' do
    before(:each) do
      @member = FactoryGirl.create(:geolocated_member)
      controller.stub(:current_user) { @member }
      sign_in @member
      assign(:member, @member)
      @planting = FactoryGirl.create(:planting,
        :garden => @member.gardens.first
      )
      assign(:plantings, [@planting])
      @forum = FactoryGirl.create(:forum, :owner => @member)
      @post = FactoryGirl.create(:post, :author => @member)
      assign(:posts, [@post])
      @role = FactoryGirl.create(:admin)
      @member.roles << @role
      render
    end

    it 'should say welcome' do
      render
      rendered.should contain "Welcome, #{@member.login_name}"
    end

    it 'mentions location' do
      rendered.should contain @member.location
    end

    it 'lists gardens' do
      assert_select "a[href=#{url_for(@member.gardens.first)}]", "Garden"
    end

    it 'lists plantings' do
      rendered.should contain "Your recent plantings"
      assert_select "a[href=#{url_for(@planting)}]"
    end

    it 'lists posts' do
      rendered.should contain "Your recent posts"
      assert_select "a[href=#{url_for(@post)}]"
    end

    it 'shows admin status' do
      rendered.should contain "You are an ADMIN USER"
    end

    it 'shows forum list' do
      assert_select "a[href=#{url_for(@forum)}]", @forum.name
    end

  end
end
