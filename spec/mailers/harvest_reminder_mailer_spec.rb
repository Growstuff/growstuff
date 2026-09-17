# frozen_string_literal: true

require 'rails_helper'

describe NotifierMailer, type: :mailer do
  let(:member) { create(:member) }
  let(:mail)   { NotifierMailer.harvest_reminder(member) }

  it "has a greeting" do
    expect(mail.body.encoded).to match "Hello"
  end

  context "when member has upcoming harvests" do
    let(:crop) { create(:crop, median_days_to_first_harvest: 20) }
    let!(:planting) { create(:planting, owner: member, crop: crop, planted_at: 15.days.ago) }
    let(:plantings) { [planting] }

    it "lists the upcoming harvest" do
      expect(mail.body.encoded).to match "Upcoming harvests in your garden"
      expect(mail.body.encoded).to match planting.crop.name
      expect(mail.body.encoded).to match (Time.zone.today + 5.days).to_date.to_s
    end

    it "has an unsubscribe link" do
      expect(mail.body.encoded).to match "Unsubscribe from harvest reminders"
    end
  end
end
