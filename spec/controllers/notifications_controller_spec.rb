require 'spec_helper'

describe NotificationsController do

  login_member

  def valid_attributes
    { "recipient_id" => subject.current_member.id }
  end

  def valid_session
    {}
  end

  describe "GET index" do
    it "assigns all notifications as @notifications" do
      notification = FactoryGirl.create(:notification, :recipient_id => subject.current_member.id)
      get :index, {}
      assigns(:notifications).should eq([notification])
    end
  end

  describe "GET show" do
    it "assigns the requested notification as @notification" do
      notification = FactoryGirl.create(:notification, :recipient_id => subject.current_member.id)
      get :show, {:id => notification.to_param}
      assigns(:notification).should eq(notification)
    end

    it "marks notifications as read" do
      notification = FactoryGirl.create(:notification, :recipient_id => subject.current_member.id)
      get :show, {:id => notification.to_param}
      # we need to fetch it from the db again, can't test against the old one
      n = Notification.find(notification.id)
      n.read.should eq true
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested notification" do
      notification = FactoryGirl.create(:notification, :recipient_id => subject.current_member.id)
      expect {
        delete :destroy, {:id => notification.to_param}
      }.to change(Notification, :count).by(-1)
    end

    it "redirects to the notifications page" do
      notification = FactoryGirl.create(:notification, :recipient_id => subject.current_member.id)
      delete :destroy, {:id => notification.to_param}
      response.should redirect_to(notifications_url)
    end
  end

end
