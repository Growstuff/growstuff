# frozen_string_literal: true

require 'rails_helper'
require 'capybara/email/rspec'

describe "Planting reminder email" do
  let(:member) { create(:member) }
  let(:mail)   { NotifierMailer.planting_reminder(member) }
  let(:mail_body) { mail.body.encoded }

  # Unfortunately, we can't use the default url options for ActionMailer as configured in
  # test.rb, since this isn't a mailer spec.
  def self.default_url_options
    { host: 'localhost', port: 8080 }
  end

  it "has a greeting" do
    expect(mail).to have_content "Hello"
  end

  context "when features were added since we last emailed the member" do
    before { member.update_columns(planting_reminder_sent_at: 1.year.ago) }

    it "says there are new features to tell them about" do
      expect(mail_body).to have_content "We have 4 new features to tell you about"
    end

    it "tells them about the features" do
      expect(mail_body).to have_link "Seed library", href: seeds_url
    end
  end

  context "when nothing was added since we last emailed the member" do
    before { member.update_columns(planting_reminder_sent_at: 1.minute.ago) }

    it "leaves out new features" do
      expect(mail_body).to have_no_content "New since we last emailed you"
    end
  end

  context "when member has no location" do
    before { member.update_columns(latitude: nil, longitude: nil) }

    it "asks for their location" do
      expect(mail_body).to have_link "Set your location", href: root_url
    end

    it "leaves out the season" do
      expect(mail_body).to have_no_content "Your garden right now"
    end
  end

  context "when member has a location" do
    before do
      member.update_columns(latitude: -41.3, longitude: 174.7)
      create(:weather_reading, date: Time.zone.today - 3, rainfall_mm: 7.0, soil_temp_c: 12.0)
    end

    it "gives the season" do
      expect(mail_body).to have_content "Your garden right now"
    end

    it "gives the soil temperature" do
      expect(mail_body).to have_content "The soil was 12.0°C"
    end

    it "gives the recent rain" do
      expect(mail_body).to have_content "7 mm of rain"
    end

    it "gives the dates the weather is from" do
      date = Time.zone.today - 3
      expect(mail_body).to have_content "From #{date.day} #{date.strftime('%B')} to #{date.day} #{date.strftime('%B')}"
    end

    context "when the readings have only a temperature" do
      before { WeatherReading.update_all(rainfall_mm: nil, temp_min_c: nil) } # rubocop:disable Rails/SkipsModelValidations

      it "gives what there is, without blanks" do
        expect(mail_body).to have_content "highs up to 15.0°C."
      end

      it "leaves out the rain" do
        expect(mail_body).to have_no_content "of rain"
      end
    end

    context "when the readings have no figures" do
      before { WeatherReading.update_all(rainfall_mm: nil, temp_min_c: nil, temp_max_c: nil) } # rubocop:disable Rails/SkipsModelValidations

      it "leaves out the weather sentence" do
        expect(mail_body).to have_no_content "From "
      end
    end

    it "doesn't ask for their location" do
      expect(mail_body).to have_no_link "Set your location"
    end
  end

  context "when member has no plantings" do
    it "tells you to track your plantings" do
      expect(mail_body).to have_content "planting your first crop"
    end

    it "doesn't list plantings" do
      expect(mail_body).not_to have_css("section.progress")
    end
  end

  context "when member has some plantings" do
    # Bangs are used on the following 2 let blocks in order to ensure that the plantings are present
    # in the database before the email is generated: otherwise, they won't be present in the email.
    let!(:recent_planting) { create(:predictable_planting, planted_at: 10.days.ago, garden: member.gardens.first, owner: member) }
    let!(:older_planting)  { create(:predictable_planting, planted_at: 30.days.ago, garden: member.gardens.first, owner: member) }

    describe "lists plantings" do
      it { expect(mail_body).to have_content "Progress report" }
      it { expect(mail_body).to have_link recent_planting.crop.to_s, href: planting_url(recent_planting) }
      it { expect(mail_body).to have_link older_planting.crop.to_s, href: planting_url(older_planting) }
      it { expect(mail_body).to have_content "keep your garden records up to date" }
    end
  end

  context "when member has a planting past its finish date" do
    let!(:late_planting) { create(:predictable_planting, planted_at: 70.days.ago, garden: member.gardens.first, owner: member) }

    it "asks them to log in and say if they stopped growing it" do
      expect(mail_body).to have_link "Log in", href: new_member_session_url
    end
  end

  context "when member has no harvests" do
    it "doesn't list plantings" do
      expect(mail_body).to have_no_content "Ready to harvest"
    end
  end

  context "when member has some harvests" do
    # Bangs are used on the following 2 let blocks in order to ensure that the plantings are present
    # in the database before the spec is run.
    let!(:recent_planting) { create(:predictable_planting, garden: member.gardens.first, owner: member, planted_at: 20.days.ago) }
    let!(:older_planting)  { create(:predictable_planting, garden: member.gardens.first, owner: member) }
    let!(:recent_harvest)  { create(:harvest, owner: member, planting: recent_planting, harvested_at: 1.day.ago) }
    let!(:older_harvest)   { create(:harvest, owner: member, planting: older_planting, harvested_at: 3.days.ago) }

    describe "lists planting that are ready for harvest" do
      it { expect(mail_body).to have_content "Ready to harvest" }
      it { expect(mail_body).to have_link recent_planting.crop.name, href: planting_url(recent_planting) }
      it { expect(mail_body).to have_link older_planting.crop.name, href: planting_url(older_planting) }
      it { expect(mail_body).to have_content "Harvested anything lately?" }
    end
  end
end
