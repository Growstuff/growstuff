require 'spec_helper'
require 'capybara/email/rspec'

feature "Planting reminder email" do
  let(:member) { FactoryGirl.create(:member) }
  let(:mail) { Notifier.planting_reminder(member) }

  scenario "has a greeting" do
    expect(mail).to have_content "Hello"
  end

  context "when member has no plantings" do
    let(:member) { FactoryGirl.create(:member) }
    let(:mail) { Notifier.planting_reminder(member) }

    scenario "tells you to tracking plantings" do
      expect(mail).to have_content "planting your first crop"
    end

    scenario "doesn't list plantings" do
      expect(mail).not_to have_content "most recent plantings you've told us about"
    end

  end

  context "when member has some plantings" do
    let(:member) { FactoryGirl.create(:member) }
    let(:mail) { Notifier.planting_reminder(member) }

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
      puts Rails.env
      puts planting_url(@p1)
      expect(mail).to have_content "most recent plantings you've told us about"
      expect(mail).to have_link @p1.to_s, :href => planting_url(@p1)
      expect(mail).to have_link @p2.to_s, :href => planting_url(@p2)
      expect(mail).to have_content "keep your garden records up to date"
    end
  end

  context "when member has no harvests" do
  end

  context "when member has some harvests" do
  end

end
