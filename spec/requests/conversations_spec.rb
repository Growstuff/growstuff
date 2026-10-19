# frozen_string_literal: true

require 'rails_helper'

describe 'Conversations' do
  describe 'DELETE destroy_multiple' do
    let!(:member) { create(:admin_member) }

    before do
      sign_in member
    end

    it 'redirects to the conversations inbox' do
      delete '/conversations/destroy_multiple', params: { conversation_ids: [] }
      expect(response).to redirect_to '/conversations'
      follow_redirect!
      expect(response).to render_template(:index)
      expect(response).to have_http_status(:ok)
    end

    it 'allows users to trash multiple inbox conversations' do
      other_member = create(:member)
      receipt1 = other_member.send_message(member, 'Body 1', 'Subject 1')
      receipt2 = other_member.send_message(member, 'Body 2', 'Subject 2')
      conversations_to_trash = [receipt1.conversation.id, receipt2.conversation.id]

      # we dont actually destroy the messages, we move them to the trash folder
      expect do
        delete '/conversations/destroy_multiple', params: { conversation_ids: conversations_to_trash, box: 'inbox' }
      end.not_to change(Mailboxer::Conversation, :count)

      expect(member.mailbox.inbox.count).to eq 0
      expect(member.mailbox.trash.count).to eq 2
    end

    it 'only deletes conversations for the current user' do
      second_member = create(:admin_member)
      receipt1 = member.send_message(second_member, 'Body 1', 'Subject 1')
      receipt2 = member.send_message(second_member, 'Body 2', 'Subject 2')
      conversations_to_trash = [receipt1.conversation.id, receipt2.conversation.id]

      # we dont actually destroy the messages, we move them to the trash folder
      expect do
        delete '/conversations/destroy_multiple', params: { conversation_ids: conversations_to_trash }
      end.not_to change(Mailboxer::Conversation, :count)

      expect(second_member.mailbox.inbox.count).to eq 2
      expect(second_member.mailbox.trash.count).to eq 0
    end

    it 'allows users to trash multiple sent conversations' do
      other_member = create(:member)
      receipt1 = member.send_message(other_member, 'Body 1', 'Subject 1')
      receipt2 = member.send_message(other_member, 'Body 2', 'Subject 2')
      conversations_to_trash = [receipt1.conversation.id, receipt2.conversation.id]

      # we dont actually destroy the messages, we move them to the trash folder
      expect do
        delete '/conversations/destroy_multiple', params: { conversation_ids: conversations_to_trash, box: 'sent' }
      end.not_to change(Mailboxer::Conversation, :count)

      expect(member.mailbox.sentbox.count).to eq 0
      expect(member.mailbox.trash.count).to eq 2
    end
  end
end
