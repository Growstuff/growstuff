## DEPRECATION NOTICE: Do not add new tests to this file!
##
## View and controller tests are deprecated in the Growstuff project. 
## We no longer write new view and controller tests, but instead write 
## feature tests (in spec/features) using Capybara (https://github.com/jnicklas/capybara). 
## These test the full stack, behaving as a browser, and require less complicated setup 
## to run. Please feel free to delete old view/controller tests as they are reimplemented 
## in feature tests. 
##
## If you submit a pull request containing new view or controller tests, it will not be 
## merged.





require 'rails_helper'

describe 'home/_blurb.html.haml', type: "view" do
  context 'signed out' do
    before :each do
      controller.stub(:current_user) { nil }
      render
    end

    it 'has description' do
      rendered.should have_content 'is a community of food gardeners'
    end

    it 'has signup section' do
      assert_select "div.signup"
      assert_select "a", href: new_member_registration_path
    end

    it 'has a link to sign in' do
      rendered.should have_content "Or sign in if you already have an account"
      assert_select "a", href: new_member_session_path
    end
  end

end
