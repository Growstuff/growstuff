require "spec_helper"

describe Notifier do

  describe "notify" do
    before(:each) do
      @notification = FactoryGirl.create(:notification)
      @mail = Notifier.notify(@notification)
    end

    it 'sets the subject correctly' do
      @mail.subject.should == @notification.subject
    end

    it 'comes from noreply@growstuff.org' do
      @mail.from.should == ['noreply@growstuff.org']
    end

    it 'sends the mail to the recipient of the notification' do
      @mail.to.should == [@notification.recipient.email]
    end

  end
end
