# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeviseMailer, type: :mailer do
  let(:member) { build(:member, email: 'user@example.com', login_name: 'testuser') }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('GROWSTUFF_SITE_NAME', 'Growstuff').and_return('Growstuff Staging')
  end

  shared_examples 'a localized email' do |action|
    subject(:mail) { described_class.public_send(action, member, 'token123') }

    around do |example|
      I18n.with_locale(:en) { example.run }
    end

    context 'with a preferred locale' do
      let(:member) { build(:member, locale: 'fr', login_name: 'testuser') }

      it 'translates the subject into the recipient locale' do
        expect(mail.subject).to eq(I18n.t("devise.mailer.#{action}.subject", locale: :fr, site_name: 'Growstuff Staging'))
      end

      it 'translates the body into the recipient locale' do
        expect(mail.body.decoded).to include(I18n.t('devise_views.greeting', locale: :fr, name: member.login_name))
      end

      it 'restores the previous locale after rendering' do
        mail.body
        expect(I18n.locale).to eq(:en)
      end
    end

    context 'without a preferred locale' do
      around do |example|
        I18n.with_locale(:fr) { example.run }
      end

      it 'uses the default locale rather than the current locale' do
        expect(mail.subject).to eq(I18n.t("devise.mailer.#{action}.subject", locale: I18n.default_locale, site_name: 'Growstuff Staging'))
      end
    end
  end

  describe '#confirmation_instructions' do
    include_examples 'a localized email', :confirmation_instructions

    subject(:mail) { described_class.confirmation_instructions(member, 'token123') }

    it 'includes the custom site name in the subject' do
      expect(mail.subject).to eq('Welcome to Growstuff Staging. Please confirm your account.')
    end
  end

  describe '#reset_password_instructions' do
    include_examples 'a localized email', :reset_password_instructions

    subject(:mail) { described_class.reset_password_instructions(member, 'token123') }

    it 'includes the custom site name in the subject' do
      expect(mail.subject).to eq('Growstuff Staging password reset instructions')
    end
  end

  describe '#unlock_instructions' do
    include_examples 'a localized email', :unlock_instructions

    subject(:mail) { described_class.unlock_instructions(member, 'token123') }

    it 'includes the custom site name in the subject' do
      expect(mail.subject).to eq('Unlock your Growstuff Staging account')
    end
  end
end
