# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeviseMailer, type: :mailer do
  let(:member) { build(:member, email: 'user@example.com', login_name: 'testuser') }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('GROWSTUFF_SITE_NAME', 'Growstuff').and_return('Growstuff Staging')
  end

  describe '#confirmation_instructions' do
    subject(:mail) { described_class.confirmation_instructions(member, 'token123') }

    it 'includes the custom site name in the subject' do
      expect(mail.subject).to eq('Welcome to Growstuff Staging. Please confirm your account.')
    end
  end

  describe '#reset_password_instructions' do
    subject(:mail) { described_class.reset_password_instructions(member, 'token123') }

    it 'includes the custom site name in the subject' do
      expect(mail.subject).to eq('Growstuff Staging password reset instructions')
    end
  end

  describe '#unlock_instructions' do
    subject(:mail) { described_class.unlock_instructions(member, 'token123') }

    it 'includes the custom site name in the subject' do
      expect(mail.subject).to eq('Unlock your Growstuff Staging account')
    end
  end
end
