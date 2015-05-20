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

describe AccountsController do

  login_member(:admin_member)

  def valid_attributes
    { "paid_until" => Time.now }
  end

  def create_account
    # account details are automatically created when you create a new
    # member; creating them manually will just cause errors as only one is
    # allowed. This method has been left here in case it's useful in
    # future.
    member = FactoryGirl.create(:member)
    return member.account
  end

end
