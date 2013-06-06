require 'spec_helper'

describe 'layouts/application.html.haml', :type => "view" do
  context "when not logged in" do

    before(:each) do
      controller.stub(:current_user) { nil }
      render
    end

    it 'shows the title' do
      rendered.should contain Growstuff::Application.config.site_name
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
      rendered.should contain /member\d+/
    end

    it "should show member's name" do
      assert_select("a[href=/members/#{@member.login_name}]", "Profile")
    end

    it "should show settings link" do
      assert_select "a[href=/members/edit]", "Settings"
    end

    it "should show settings link" do
      assert_select "a[href=#{orders_path}]", "Account"
    end

    it 'should show logout link' do
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

    it 'includes the analytics code' do
      Growstuff::Application.config.analytics_code = '<script>alert("foo!")</script>'
      render
      assert_select "script", :text => 'alert("foo!")'
      rendered.should_not contain 'script'
    end

  end
end
