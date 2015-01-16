require 'rails_helper'

describe GardensController do

  login_member

  def valid_attributes
    member = FactoryGirl.create(:member)
    {:name => 'My Garden', :owner_id => member.id }
  end

end
