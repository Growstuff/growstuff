# frozen_string_literal: true

require 'rails_helper'

describe 'members/_email_prompt' do
  subject { rendered }

  context 'when member has no email address' do
    let(:member) { build_stubbed(:member, email: nil) }

    before do
      render partial: 'members/email_prompt', locals: { member: }
    end

    it 'renders the localized unset title' do
      expect(subject).to have_content(I18n.t('members.email_prompt.unset_title'))
    end

    it 'renders the localized unset body' do
      expect(subject).to have_content(I18n.t('members.email_prompt.unset_body'))
    end

    it 'renders the localized add email link' do
      expect(subject).to have_link(
        I18n.t('members.email_prompt.add_email'),
        href: edit_member_registration_path(anchor: 'email')
      )
    end
  end

  context 'when member is pending email reconfirmation' do
    let(:member) do
      build_stubbed(:member, email: 'current@example.com', unconfirmed_email: 'new@example.com')
    end

    before do
      render partial: 'members/email_prompt', locals: { member: }
    end

    it 'renders the localized waiting title' do
      expect(subject).to have_content(I18n.t('members.email_prompt.waiting_title'))
    end

    it 'renders the localized waiting body with unconfirmed email' do
      expect(subject).to have_content(
        I18n.t('members.email_prompt.waiting_body', email: member.unconfirmed_email)
      )
    end
  end
end
