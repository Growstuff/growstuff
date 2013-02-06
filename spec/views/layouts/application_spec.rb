require 'spec_helper'

describe 'layouts/application.html.haml', :type => "view" do
  context "when not logged in" do

    before(:each) do
      controller.stub(:current_user) { nil }
      render
    end

    it 'shows the title' do
      rendered.should contain 'Growstuff'
      rendered.should contain 'development site'
    end

    it 'should have signup/login links' do
      rendered.should contain 'Sign up'
      rendered.should contain 'Sign in'
    end

  end

  context "logged in" do

    before(:each) do
      @member = FactoryGirl.create(:member)
      sign_in @member
      controller.stub(:current_user) { @member }
      render
    end

    it 'should show login name' do
      rendered.should contain 'member1'
    end

    it 'should have a "Post" link' do
      rendered.should contain 'Post something'
    end

    it 'should have a plant something link' do
      rendered.should contain 'Plant something'
    end

    it "should show member's name" do
      assert_select("a[href=/members/#{@member.login_name}]", "Profile")
    end

    it "should show settings link" do
      assert_select "a[href=/members/edit]", "Settings"
    end

    it 'should show logout link' do
      rendered.should contain 'Sign out'
    end

  end
end
