require 'spec_helper'

describe 'layouts/application.html.haml', :type => "view" do
  context "when not logged in" do

    before(:each) do
      view.stub(:member_signed_in).and_return(false)
      view.stub(:current_member).and_return(nil)
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
      @member = FactoryGirl.create(:member)
      sign_in @member
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

    it 'should show logout link' do
      rendered.should contain 'Log out'
    end

  end
end
