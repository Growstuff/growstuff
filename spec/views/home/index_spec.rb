require 'spec_helper'

describe 'home/index.html.haml', :type => "view" do
  context 'logged out' do
    before(:each) do
      render
    end

    it 'should have description' do
      rendered.should contain 'Growstuff is a community of food gardeners'
      rendered.should contain 'We welcome you regardless of your experience, and invite you to be part of our development process.'
    end
  end

  context 'logged in' do
    before(:each) do
      @member = FactoryGirl.create(:geolocated_member)
      controller.stub(:current_user) { @member }
      sign_in @member
      @planting = FactoryGirl.create(:planting,
        :garden => @member.gardens.first
      )
      @forum = FactoryGirl.create(:forum, :owner => @member)
      @post = FactoryGirl.create(:post, :author => @member)
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
