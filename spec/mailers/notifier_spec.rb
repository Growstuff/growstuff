require "spec_helper"

describe Notifier do

  describe "notifications" do
    let(:notification) { FactoryGirl.create(:notification) }
    let(:mail) { Notifier.notify(notification) }

    it 'sets the subject correctly' do
      mail.subject.should == notification.subject
    end

    it 'comes from noreply@growstuff.org' do
      mail.from.should == ['noreply@growstuff.org']
    end

    it 'sends the mail to the recipient of the notification' do
      mail.to.should == [notification.recipient.email]
    end
  end

  describe "planting reminders" do
    let(:member) { FactoryGirl.create(:member) }
    let(:mail) { Notifier.planting_reminder(member) }

    it 'sets the subject correctly' do
      mail.subject.should == "What have you planted lately?"
    end

    it 'comes from noreply@growstuff.org' do
      mail.from.should == ['noreply@growstuff.org']
    end

    it 'sends the mail to the recipient of the notification' do
      mail.to.should == [member.email]
    end

    it 'includes the new planting URL' do
      mail.body.encoded.should match new_planting_path
    end

    it 'includes the new harvest URL' do
      mail.body.encoded.should match new_harvest_path
    end

  end
end
