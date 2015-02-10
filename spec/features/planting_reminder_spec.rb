require 'rails_helper'
require 'capybara/email/rspec'

feature "Planting reminder email", :js => true do
  let(:member) { FactoryGirl.create(:member) }
  let(:mail) { Notifier.planting_reminder(member) }

  # Unfortunately, we can't use the default url options for ActionMailer as configured in 
  # test.rb, since this isn't a mailer spec.
  def self.default_url_options
    { host: 'localhost', port: 8080 }
  end

  scenario "has a greeting" do
    expect(mail).to have_content "Hello"
  end

  context "when member has no plantings" do
    scenario "tells you to track your plantings" do
      expect(mail).to have_content "planting your first crop"
    end

    scenario "doesn't list plantings" do
      expect(mail).not_to have_content "most recent plantings you've told us about"
    end

  end

  context "when member has some plantings" do
    before :each do
      @p1 = FactoryGirl.create(:planting,
        :garden => member.gardens.first,
        :owner => member
      )
      @p2 = FactoryGirl.create(:planting,
        :garden => member.gardens.first,
        :owner => member
      )
    end

    scenario "lists plantings" do
      expect(mail).to have_content "most recent plantings you've told us about"
      expect(mail).to have_link @p1.to_s, planting_url(@p1)
      expect(mail).to have_link @p2.to_s, planting_url(@p2)
      expect(mail).to have_content "keep your garden records up to date"
    end
  end

  context "when member has no harvests" do
    scenario "tells you to tracking plantings" do
      expect(mail).to have_content "Get started now by tracking your first harvest"
    end

    scenario "doesn't list plantings" do
      expect(mail).not_to have_content "the last few things you harvested were"
    end

  end

  context "when member has some harvests" do
    before :each do
      @h1 = FactoryGirl.create(:harvest,
        :owner => member
      )
      @h2 = FactoryGirl.create(:harvest,
        :owner => member
      )
    end

    scenario "lists harvests" do
      expect(mail).to have_content "the last few things you harvested were"
      expect(mail).to have_link @h1.to_s, harvest_url(@h1)
      expect(mail).to have_link @h2.to_s, harvest_url(@h2)
      expect(mail).to have_content "Harvested anything else lately?"
    end

  end

end
