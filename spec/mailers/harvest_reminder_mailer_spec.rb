# frozen_string_literal: true

require 'rails_helper'

describe NotifierMailer, type: :mailer do
  let(:member) { create(:member) }
  let(:mail)   { NotifierMailer.harvest_reminder(member) }

  it "has a greeting" do
    expect(mail.body.encoded).to match "Hello"
  end

  describe "layout, branding and footer" do
    let(:html_body) { mail.html_part ? mail.html_part.body.decoded : mail.body.decoded }

    describe "includes Growstuff branding in the header" do
      it { expect(html_body).to include("Growstuff") }
      it { expect(html_body).to include(root_url) }
    end

    describe "uses email-appropriate fonts" do
      it { expect(html_body).to include("font-family") }
      it { expect(html_body).to include("Raleway") }
      it { expect(html_body).to include("Fira Sans") }
    end

    describe "includes a footer indicating origin from growstuff.org" do
      it { expect(html_body).to include("This email was sent by") }
      it { expect(html_body).to include("growstuff.org") }
      it { expect(html_body).to include(policy_community_url) }
      it { expect(html_body).to include(contact_url) }
    end
  end

  context "when member has upcoming harvests" do
    let(:crop) { create(:crop, median_days_to_first_harvest: 20) }
    let!(:planting) { create(:planting, owner: member, crop: crop, planted_at: 15.days.ago) }
    let(:plantings) { [planting] }

    describe "lists the upcoming harvest" do
      it { expect(mail.body.encoded).to match "Upcoming harvests in your garden" }
      it { expect(mail.body.encoded).to match planting.crop.name }
      it { expect(mail.body.encoded).to match (Time.zone.today + 5.days).to_date.to_s }
    end

    it "has an unsubscribe link" do
      expect(mail.body.encoded).to match "Unsubscribe from harvest reminders"
    end
  end
end
