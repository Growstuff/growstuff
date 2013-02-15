require 'spec_helper'

describe NotificationsController do

  login_member

  def valid_attributes
    { "to_id" => subject.current_member.id }
  end

  def valid_session
    {}
  end

  describe "GET index" do
    it "assigns all notifications as @notifications" do
      notification = Notification.create! valid_attributes
      get :index, {}
      assigns(:notifications).should eq([notification])
    end
  end

  describe "GET show" do
    it "assigns the requested notification as @notification" do
      notification = Notification.create! valid_attributes
      get :show, {:id => notification.to_param}
      assigns(:notification).should eq(notification)
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested notification" do
      notification = Notification.create! valid_attributes
      expect {
        delete :destroy, {:id => notification.to_param}
      }.to change(Notification, :count).by(-1)
    end

    it "redirects to the notifications page" do
      notification = Notification.create! valid_attributes
      delete :destroy, {:id => notification.to_param}
      response.should redirect_to(notifications_url)
    end
  end

end
