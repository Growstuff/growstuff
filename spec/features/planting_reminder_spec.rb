# frozen_string_literal: true

require 'rails_helper'
require 'capybara/email/rspec'

describe "Planting reminder email", :js do
  let(:member) { create :member                     }
  let(:mail)   { Notifier.planting_reminder(member) }

  # Unfortunately, we can't use the default url options for ActionMailer as configured in
  # test.rb, since this isn't a mailer spec.
  def self.default_url_options
    { host: 'localhost', port: 8080 }
  end

  it "has a greeting" do
    expect(mail).to have_content "Hello"
  end

  context "when member has no plantings" do
    it "tells you to track your plantings" do
      expect(mail).to have_content "planting your first crop"
    end

    it "doesn't list plantings" do
      expect(mail).not_to have_content "Progress report"
    end
  end

  context "when member has some plantings" do
    # Bangs are used on the following 2 let blocks in order to ensure that the plantings are present
    # in the database before the email is generated: otherwise, they won't be present in the email.
    let!(:p1) { FactoryBot.create :predicatable_planting, planted_at: 10.days.ago, garden: member.gardens.first, owner: member }
    let!(:p2) { FactoryBot.create :predicatable_planting, planted_at: 30.days.ago, garden: member.gardens.first, owner: member }

    describe "lists plantings" do
      it { expect(mail).to have_content "Progress report" }
      it { expect(mail).to have_link p1.crop.to_s, href: planting_url(p1) }
      it { expect(mail).to have_link p2.crop.to_s, href: planting_url(p2) }
      it { expect(mail).to have_content "keep your garden records up to date" }
    end
  end

  context "when member has no harvests" do
    it "doesn't list plantings" do
      expect(mail).not_to have_content "Ready to harvest"
    end
  end

  context "when member has some harvests" do
    # Bangs are used on the following 2 let blocks in order to ensure that the plantings are present
    # in the database before the spec is run.
    let!(:p1) { FactoryBot.create :predicatable_planting, garden: member.gardens.first, owner: member, planted_at: 20.days.ago }
    let!(:p2) { FactoryBot.create :predicatable_planting, garden: member.gardens.first, owner: member }
    let!(:h1) { FactoryBot.create :harvest, owner: member, planting: p1, harvested_at: 1.day.ago }
    let!(:h2) { FactoryBot.create :harvest, owner: member, planting: p2, harvested_at: 3.days.ago }

    describe "lists planting that are ready for harvest" do
      it { expect(mail).to have_content "Ready to harvest" }
      it { expect(mail).to have_link p1.crop.name, href: planting_url(p1) }
      it { expect(mail).to have_link p2.crop.name, href: planting_url(p2) }
      it { expect(mail).to have_content "Harvested anything lately?" }
    end
  end
end
