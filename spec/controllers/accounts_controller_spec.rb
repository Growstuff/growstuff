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
