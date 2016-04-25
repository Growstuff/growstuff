require "rails_helper"

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


  describe "new crop request" do
    let(:member) { FactoryGirl.create(:crop_wrangling_member) }
    let(:crop) { FactoryGirl.create(:crop_request) }
    let(:mail) { Notifier.new_crop_request(member, crop) }

    it 'sets the subject correctly' do
      mail.subject.should == "#{crop.requester.login_name} has requested Ultra berry as a new crop"
    end

    it 'comes from noreply@growstuff.org' do
      mail.from.should == ['noreply@growstuff.org']
    end

    it 'sends the mail to the recipient of the notification' do
      mail.to.should == [member.email]
    end

    it 'includes the requested crop URL' do
      mail.body.encoded.should match crop_url(crop)
    end
  end

  describe "new seed trade" do
    let(:seed_trade) { FactoryGirl.create(:seed_trade) }
    let(:mail) { Notifier.new_seed_trade_request(seed_trade) }

    it 'sets the subject correctly' do
      subject  = "#{seed_trade.requester.login_name} has requested "
      subject += "#{seed_trade.seed.crop.name} seeds from you"
      expect(mail.subject).to eq subject
    end

    it { expect(mail.from).to eq ["noreply@growstuff.org"] }

    it { expect(mail.to).to eq [seed_trade.seed.owner.email] }

    it { expect(mail.body).to match seed_trade.message }

    it { expect(mail.body.encoded).to match member_seed_trades_url(seed_trade.seed.owner.id) }

    it { expect(mail.body.encoded).to match member_seed_trade_url(seed_trade.seed.owner.id, seed_trade.id) }

    it 'has unsubscribe url' do
      verifier = ActiveSupport::MessageVerifier.new(ENV['RAILS_SECRET_TOKEN'])
      member_id = seed_trade.seed.owner.id
      signed_message = verifier.generate ({ member_id: member_id,
        type: :send_notification_email })
      expect(mail.body.encoded).to match unsubscribe_member_url(signed_message)
    end
  end

  describe "crop approved" do
    let(:member) { FactoryGirl.create(:member) }
    let(:crop) { FactoryGirl.create(:crop) }
    let(:mail) { Notifier.crop_request_approved(member, crop) }

    it 'sets the subject correctly' do
      expect(mail.subject).to eq "Magic bean has been approved"
    end

    it 'comes from noreply@growstuff.org' do
      expect(mail.from).to eq ['noreply@growstuff.org']
    end

    it 'sends the mail to the recipient of the notification' do
      expect(mail.to).to eq [member.email]
    end

    it 'includes the approved crop URL' do
      expect(mail.body.encoded).to match crop_url(crop)
    end

    it 'includes links to plant, harvest and stash seeds for the new crop' do
      expect(mail.body.encoded).to match "#{new_planting_url}\\?crop_id=#{crop.id}"
      expect(mail.body.encoded).to match "#{new_harvest_url}\\?crop_id=#{crop.id}"
      expect(mail.body.encoded).to match "#{new_seed_url}\\?crop_id=#{crop.id}"
    end

  end

  describe "crop rejected" do
    let(:member) { FactoryGirl.create(:member) }
    let(:crop) { FactoryGirl.create(:rejected_crop) }
    let(:mail) { Notifier.crop_request_rejected(member, crop) }

    it 'sets the subject correctly' do
      expect(mail.subject).to eq "Fail bean has been rejected"
    end

    it 'comes from noreply@growstuff.org' do
      expect(mail.from).to eq ['noreply@growstuff.org']
    end

    it 'sends the mail to the recipient of the notification' do
      expect(mail.to).to eq [member.email]
    end

    it 'includes the rejected crop URL' do
      expect(mail.body.encoded).to match crop_url(crop)
    end

    it 'includes the reason for rejection' do
      expect(mail.body.encoded).to match "Totally fake"
    end
  end

end
