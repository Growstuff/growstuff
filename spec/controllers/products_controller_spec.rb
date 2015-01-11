require 'rails_helper'

describe ProductsController do

  login_member(:admin_member)

  def valid_attributes
    {
      :name => "product name",
      :description => 'some description',
      :min_price => 9.99
    }
  end

  def valid_session
    {}
  end

end
