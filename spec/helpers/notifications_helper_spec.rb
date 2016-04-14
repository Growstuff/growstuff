require 'rails_helper'

describe NotificationsHelper do
  describe "reply_link" do

    let(:member) { FactoryGirl.create(:member) } 

    it "replies to PMs with PMs" do
      notification = FactoryGirl.create(:notification, recipient_id: member.id, post_id: nil)
      subject = "Re: " + notification.subject

      link = helper.reply_link(notification)
      link.should_not be_nil
      link.should eq reply_notification_url(notification)
    end

    it "replies to post comments with post comments" do
      notification = FactoryGirl.create(:notification, recipient_id: member.id)

      link = helper.reply_link(notification)
      link.should_not be_nil
      link.should eq new_comment_url(
        post_id: notification.post.id
      )
    end


  end
end
