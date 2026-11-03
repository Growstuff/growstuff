# frozen_string_literal: true

require 'rails_helper'

describe 'stalls/_about_growstuff' do
  subject { rendered }

  let(:member) { build_stubbed(:member) }

  context 'with default locale' do
    before do
      render partial: 'stalls/about_growstuff', locals: { member: }
    end

    it 'renders the localized brand heading' do
      expect(subject).to have_css('h2.stall-about-brand', text: 'Growstuff')
    end

    it 'renders the localized description text' do
      expect(subject).to have_content(I18n.t('stalls.about_growstuff.text', name: member))
    end

    it 'renders the localized join link' do
      expect(subject).to have_link(
        I18n.t('stalls.about_growstuff.join'),
        href: new_member_registration_path
      )
    end

    it 'renders the localized sign in link' do
      expect(subject).to have_link(
        I18n.t('stalls.about_growstuff.sign_in'),
        href: new_member_session_path
      )
    end
  end

  context 'with a non-default locale' do
    around do |example|
      I18n.with_locale(:es) { example.run }
    end

    before do
      render partial: 'stalls/about_growstuff', locals: { member: }
    end

    it 'renders the localized description in Spanish' do
      expect(subject).to have_content(I18n.t('stalls.about_growstuff.text', name: member))
    end

    it 'renders the localized join link in Spanish' do
      expect(subject).to have_link(
        I18n.t('stalls.about_growstuff.join'),
        href: new_member_registration_path
      )
    end

    it 'renders the localized sign in link in Spanish' do
      expect(subject).to have_link(
        I18n.t('stalls.about_growstuff.sign_in'),
        href: new_member_session_path
      )
    end
  end
end
