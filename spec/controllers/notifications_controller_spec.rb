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

describe NotificationsController do

  login_member

  def valid_attributes
    {
      "recipient_id" => subject.current_member.id,
      "sender_id" => FactoryGirl.create(:member).id,
      "subject" => 'test'
    }
  end

  # this gets a bit confused because for most of the notification tests
  # (reading, etc) the logged in member needs to be the recipient.
  # However, for sending private messages (create, etc) the logged in
  # member needs to be the sender.  Hence this separate set of
  # attributes.
  def valid_attributes_for_sender
    {
      "sender_id" => subject.current_member.id,
      "recipient_id" => FactoryGirl.create(:member).id,
      "subject" => 'test'
    }
  end

  def valid_session
    {}
  end

  describe "GET index" do
    it "assigns all notifications as @notifications" do
      notification = FactoryGirl.create(:notification, recipient_id: subject.current_member.id)
      get :index, {}
      assigns(:notifications).should eq([notification])
    end
  end

  describe "GET show" do
    it "assigns the requested notification as @notification" do
      notification = FactoryGirl.create(:notification, recipient_id: subject.current_member.id)
      get :show, {id: notification.to_param}
      assigns(:notification).should eq(notification)
    end

    it "assigns the reply link for a post comment" do
      notification = FactoryGirl.create(:notification, recipient_id: subject.current_member.id)

      get :show, {id: notification.to_param}
      assigns(:reply_link).should_not be_nil
      assigns(:reply_link).should eq new_comment_url(
        post_id: notification.post.id
      )
    end

    it "marks notifications as read" do
      notification = FactoryGirl.create(:notification, recipient_id: subject.current_member.id)
      get :show, {id: notification.to_param}
      # we need to fetch it from the db again, can't test against the old one
      n = Notification.find(notification.id)
      n.read.should eq true
    end
  end

  describe "GET reply" do
    it "marks notifications as read" do
      notification = FactoryGirl.create(:notification, :recipient_id => subject.current_member.id)
      get :reply, {:id => notification.to_param}
      # we need to fetch it from the db again, can't test against the old one
      n = Notification.find(notification.id)
      n.read.should eq true
    end
  end

  describe "GET new" do
    it "assigns a recipient" do
      @recipient = FactoryGirl.create(:member)
      get :new, {recipient_id: @recipient.id }
      assigns(:recipient).should be_an_instance_of(Member)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "redirects to the recipient's profile" do
        @recipient = FactoryGirl.create(:member)
        post :create, { notification: { recipient_id: @recipient.id, subject: 'foo' } }
        response.should redirect_to(notifications_path)
      end
    end

  end
end
