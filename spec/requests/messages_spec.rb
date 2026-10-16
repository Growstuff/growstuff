# frozen_string_literal: true

require 'rails_helper'

describe 'Messages' do
  let(:member) { create(:member) }
  let(:recipient) { create(:member) }
  let(:seed) { create(:seed, owner: recipient, tradable_to: 'locally') }
  let(:subject_line) { "Interested in your #{seed.crop} seeds" }

  describe 'GET new' do
    before { sign_in member }

    context 'when asking about a seed' do
      before { get new_message_path(recipient_id: recipient.id, subject: subject_line, seed_id: seed.id) }

      it { expect(response.body).to include(%(value="#{subject_line}")) }
      it { expect(response.body).to include(seed_path(seed)) }
      it { expect(response.body).to include(%(name="seed_id")) }
    end

    context 'when the seed is not the recipient\'s' do
      let(:seed) { create(:seed, tradable_to: 'locally') }

      before { get new_message_path(recipient_id: recipient.id, seed_id: seed.id) }

      it { expect(response.body).not_to include(%(name="seed_id")) }
    end

    context 'without a seed' do
      before { get new_message_path(recipient_id: recipient.id) }

      it { expect(response.body).not_to include(%(name="seed_id")) }
    end
  end

  describe 'POST create' do
    before { sign_in member }

    let(:params) { { recipient_id: recipient.id, subject: subject_line, body: 'Could I have some?', seed_id: seed.id } }

    context 'when asking about a seed' do
      before { post '/messages', params: }

      it { expect(Mailboxer::Message.last.notified_object).to eq seed }
      it { expect(Mailboxer::Conversation.last.subject).to eq subject_line }
      it { expect(response).to redirect_to conversations_path(box: 'sentbox') }
    end

    context 'when the seed is not the recipient\'s' do
      let(:seed) { create(:seed, tradable_to: 'locally') }

      before { post '/messages', params: }

      it { expect(Mailboxer::Message.last.notified_object).to be_nil }
    end

    context 'without a seed' do
      before { post '/messages', params: params.except(:seed_id) }

      it { expect(Mailboxer::Message.last.notified_object).to be_nil }
    end
  end

  describe 'the conversation about a seed' do
    let(:conversation) do
      receipt = member.send_message(recipient, 'Could I have some?', subject_line)
      receipt.notification.update(notified_object: seed)
      receipt.conversation
    end

    before do
      sign_in recipient
      get conversation_path(conversation)
    end

    it { expect(response.body).to include("About") }
    it { expect(response.body).to include(seed_path(seed)) }
  end
end
