# frozen_string_literal: true

require 'rails_helper'

describe "conversations/show" do
  subject { render }

  let(:sender) { create(:member) }
  let(:recipient) { create(:member) }
  let(:receipt) { sender.send_message(recipient, "Test message content", "Subject of conversation") }
  let(:conversation) { receipt.conversation }

  before do
    controller.stub(:current_user) { recipient }
    assign(:conversation, conversation)
    assign(:participants, conversation.participants)
    render
  end

  describe "renders conversation attributes and translations" do
    it { is_expected.to have_content conversation.subject }
    it { is_expected.to have_content "Test message content" }
    it { is_expected.to have_content I18n.t('conversations.show.participants') }
    it { is_expected.to have_content I18n.t('conversations.show.sent_on', date: conversation.messages.first.created_at) }

    it 'renders localized breadcrumb link to conversations' do
      expect(view.content_for(:breadcrumbs)).to have_link(
        I18n.t('conversations.show.breadcrumb_conversations'),
        href: conversations_path
      )
    end
  end
end
