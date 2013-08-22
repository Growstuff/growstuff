require 'spec_helper'

describe 'home/_blurb.html.haml', :type => "view" do
  context 'signed out' do
    before :each do
      controller.stub(:current_user) { nil }
      render
    end

    it 'has description' do
      rendered.should contain 'is a community of food gardeners'
    end

    it 'has signup section' do
      assert_select "div.signup"
      assert_select "a", :href => new_member_registration_path
    end

    it 'has a link to sign in' do
      rendered.should contain "Or sign in if you already have an account"
      assert_select "a", :href => new_member_session_path
    end
  end

end
