# Taken unashamedly from https://github.com/plataformatec/devise/wiki/How-To%3a-Controllers-and-Views-tests-with-Rails-3-%28and-rspec%29
module ControllerMacros
  def login_member
    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:member]
      member = FactoryGirl.create(:member)
      sign_in member
    end
  end

  def login_admin_member
    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:member]
      member = FactoryGirl.create(:admin_member)
      sign_in member
    end
  end
end
