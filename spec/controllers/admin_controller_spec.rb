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

describe AdminController do
  login_member(:admin_member)

  describe "GET admin/newsletter" do
    it 'fetches the admin newsletter page' do
      get :newsletter
      response.should be_success
      response.should render_template("admin/newsletter")
    end

    it 'assigns @members' do
      m = FactoryBot.create(:newsletter_recipient_member)
      get :newsletter
      assigns(:members).should eq [m]
    end
  end
end
