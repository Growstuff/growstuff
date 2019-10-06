require 'rails_helper'
require 'capybara/email/rspec'

describe 'Planting reminder email', :js do
  let(:member) { create :member }
  let(:mail) { Notifier.planting_reminder(member) }

  # Unfortunately, we can't use the default url options for ActionMailer as configured in
  # test.rb, since this isn't a mailer spec.
  def self.default_url_options
    { host: 'localhost', port: 8_080 }
  end

  it 'has a greeting' do
    expect(mail).to have_content 'Hello'
  end

  context 'when member has no plantings' do
    it 'tells you to track your plantings' do
      expect(mail).to have_content 'planting your first crop'
    end

    it "doesn't list plantings" do
      expect(mail).not_to have_content "most recent plantings you've told us about"
    end
  end

  context 'when member has some plantings' do
    # Bangs are used on the following 2 let blocks in order to ensure that the plantings are present
    # in the database before the email is generated: otherwise, they won't be present in the email.
    let!(:p1) { create :planting, garden: member.gardens.first, owner: member }
    let!(:p2) { create :planting, garden: member.gardens.first, owner: member }

    it 'lists plantings' do
      expect(mail).to have_content "most recent plantings you've told us about"
      expect(mail).to have_link p1.to_s, href: planting_url(p1)
      expect(mail).to have_link p2.to_s, href: planting_url(p2)
      expect(mail).to have_content 'keep your garden records up to date'
    end
  end

  context 'when member has no harvests' do
    it 'tells you to tracking plantings' do
      expect(mail).to have_content 'Get started now by tracking your first harvest'
    end

    it "doesn't list plantings" do
      expect(mail).not_to have_content 'the last few things you harvested were'
    end
  end

  context 'when member has some harvests' do
    # Bangs are used on the following 2 let blocks in order to ensure that the plantings are present
    # in the database before the spec is run.
    let!(:h1) { create :harvest, owner: member }
    let!(:h2) { create :harvest, owner: member }

    it 'lists harvests' do
      expect(mail).to have_content 'the last few things you harvested were'
      expect(mail).to have_link h1.to_s, href: harvest_url(h1)
      expect(mail).to have_link h2.to_s, href: harvest_url(h2)
      expect(mail).to have_content 'Harvested anything else lately?'
    end
  end
end
