require 'spec_helper'

describe 'home/index.html.erb', :type => "view" do
  context "when not logged in" do

    before(:each) do
      view.stub(:user_signed_in).and_return(false)
      view.stub(:current_user).and_return(nil)
    end

    it 'shows the homepage' do
        render
        rendered.should contain 'Growstuff'
    end

    it 'should have signup/login links' do
        render
        rendered.should contain 'Sign up'
        rendered.should contain 'Log in'
    end

  end

  context "logged in" do

    before(:each) do
      @user = User.create(:email => "growstuff@example.com", :password => "irrelevant")
      sign_in @user
    end

    it 'should show username' do
      render
      rendered.should contain 'You are signed in as'
      rendered.should contain 'growstuff@example.com'
    end

    it 'should show logout link' do
      render
      rendered.should contain 'Log out'
    end
  end
end
