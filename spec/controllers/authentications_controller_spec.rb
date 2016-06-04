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

describe AuthenticationsController do

  before(:each) do
    @member = FactoryGirl.create(:member)
    sign_in @member
    controller.stub(:current_member) { @member }
    @auth = FactoryGirl.create(:authentication, member: @member)
    request.env['omniauth.auth'] = {
      'provider' => 'foo',
      'uid' => 'bar',
      'info' => { 'nickname' => 'blah' },
      'credentials' => { 'token' => 'blah', 'secret' => 'blah' }
    }
  end

end
