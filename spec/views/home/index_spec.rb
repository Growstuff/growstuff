require 'spec_helper'

describe 'home/index.html.haml', :type => "view" do
  context "when not logged in" do

    before(:each) do
      view.stub(:user_signed_in).and_return(false)
      view.stub(:current_user).and_return(nil)
      render
    end

    it 'shows the homepage' do
        rendered.should contain 'Growstuff'
    end

    it 'should have signup/login links' do
        rendered.should contain 'Sign up'
        rendered.should contain 'Log in'
    end

    it 'should have description' do
        render
        rendered.should contain 'Growstuff is a community of food gardeners'
        rendered.should contain 'We welcome you regardless of your experience, and invite you to be part of our development process.'
    end

  end

  context "logged in" do

    before(:each) do
      @user = User.create(:email => "growstuff@example.com", :password => "irrelevant")
      @user.confirm!
      sign_in @user
      render
    end

    it 'should show username' do
      rendered.should contain 'You are signed in as'
      rendered.should contain 'growstuff@example.com'
    end

    it 'should show logout link' do
      rendered.should contain 'Log out'
    end

    it 'should have description' do
        render
        rendered.should contain 'Growstuff is a community of food gardeners'
        rendered.should contain 'We welcome you regardless of your experience, and invite you to be part of our development process.'
    end

  end
end
