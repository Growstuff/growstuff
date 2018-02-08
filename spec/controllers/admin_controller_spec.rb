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
