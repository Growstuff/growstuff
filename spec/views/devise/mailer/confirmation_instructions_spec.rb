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

describe 'devise/mailer/confirmation_instructions.html.haml', type: "view" do

  context "logged in" do
    before(:each) do
      @resource = FactoryGirl.create(:member)
      render
    end

    it 'should have a confirmation link' do
      rendered.should have_content 'Confirm my account'
    end

    it 'should have a link to the homepage' do
      rendered.should have_content root_url
    end
  end
end
