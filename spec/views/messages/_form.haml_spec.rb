# frozen_string_literal: true

require 'rails_helper'

describe "messages/_form" do
  subject { rendered }

  let(:recipient) { create(:member) }

  context 'when composing a message to a recipient' do
    before do
      assign(:recipient, recipient)
      render
    end

    it { is_expected.to have_content I18n.t('messages.form.to') }
    it { is_expected.to have_link recipient.to_s, href: member_path(recipient) }
    it { is_expected.to have_field I18n.t('messages.form.type_your_message') }
    it { is_expected.to have_link I18n.t('messages.form.cancel'), href: conversations_path }
    it { is_expected.to have_button I18n.t('messages.form.send') }
  end

  context 'when asking about a seed' do
    let(:crop) { create(:crop, name: 'Tomato') }
    let(:seed) { create(:seed, crop:, owner: recipient) }

    before do
      assign(:recipient, recipient)
      assign(:seed, seed)
      render
    end

    it { is_expected.to have_content I18n.t('messages.form.about') }

    it 'renders localized link to seed' do
      expect(rendered).to have_link(
        I18n.t('messages.form.crop_seeds', crop: seed.crop_name),
        href: seed_path(seed)
      )
    end
  end

  context 'when replying to a conversation' do
    let(:sender) { create(:member) }
    let(:receipt) { sender.send_message(recipient, "Original message", "Hello") }
    let(:conversation) { receipt.conversation }

    before do
      assign(:conversation, conversation)
      render
    end

    it { is_expected.to have_field I18n.t('messages.form.type_your_message') }
    it { is_expected.to have_button I18n.t('messages.form.send') }
    it { is_expected.to have_link I18n.t('messages.form.cancel'), href: conversations_path }
  end
end
