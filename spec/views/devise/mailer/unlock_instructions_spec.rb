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
describe 'devise/mailer/unlock_instructions.html.haml', type: "view" do
  context "logged in" do
    before(:each) do
      @resource = FactoryGirl.create(:member)
      render
    end

    it "should explain what's happened" do
      rendered.should have_content "account has been locked"
    end

    it "should have an unlock link" do
      rendered.should have_content "Unlock my account"
    end
  end
end

