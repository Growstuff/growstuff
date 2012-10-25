require 'spec_helper'

describe 'layouts/application.html.haml', :type => "view" do
  context "when not logged in" do

    before(:each) do
      view.stub(:user_signed_in).and_return(false)
      view.stub(:current_user).and_return(nil)
      render
    end

    it 'shows the title' do
        rendered.should contain 'Growstuff'
        rendered.should contain 'development site'
    end

    it 'should have signup/login links' do
        rendered.should contain 'Sign up'
        rendered.should contain 'Log in'
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

  end
end
