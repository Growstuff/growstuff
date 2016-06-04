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

describe 'devise/mailer/reset_password_instructions.html.haml', type: "view" do

  context "logged in" do
    before(:each) do
      @resource = mock_model(Member)
      @resource.stub(:email).and_return("example@example.com")
      @resource.stub(:reset_password_token).and_return("joe")
      render
    end

    it 'should have some of the right text' do
      rendered.should have_content 'Change my password'
      rendered.should have_content 'Someone has requested a link to reset your password'
    end
  end
end
