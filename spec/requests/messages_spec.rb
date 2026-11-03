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
      it { expect(response).to redirect_to conversations_path(box: 'sent') }
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

    context 'with an empty body' do
      before { post '/messages', params: params.merge(body: '') }

      it 'returns a validation failure' do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'shows the validation error' do
        expect(Capybara.string(response.body)).to have_content("Body can't be blank")
      end

      it 'does not create a conversation' do
        expect(Mailboxer::Conversation.count).to eq 0
      end
    end

    context 'when replying to a conversation' do
      let(:conversation) { member.send_message(recipient, 'Hello', 'Seeds').conversation }
      let(:reply_params) { { conversation_id: conversation.id, body: 'A reply' } }

      it 'delivers a participant\'s reply' do
        conversation
        expect { post '/messages', params: reply_params }.to change { conversation.messages.count }.by(1)
      end

      context 'when a recipient has blocked the sender' do
        before do
          conversation
          recipient.blocks.create!(blocked: member)
        end

        it 'does not deliver the reply' do
          expect { post '/messages', params: reply_params }.not_to change(Mailboxer::Message, :count)
        end

        it 'explains why the reply was rejected' do
          post '/messages', params: reply_params
          expect(flash[:error]).to include('has blocked you')
        end
      end

      context 'when the sender is not a participant' do
        before do
          conversation
          sign_in create(:member)
        end

        it 'rejects the request' do
          post '/messages', params: reply_params
          expect(response).to have_http_status(:forbidden)
        end

        it 'does not create a message' do
          expect { post '/messages', params: reply_params }.not_to change(Mailboxer::Message, :count)
        end

        it 'does not create a receipt' do
          expect { post '/messages', params: reply_params }.not_to change(Mailboxer::Receipt, :count)
        end
      end

      context 'with an empty reply' do
        before { post '/messages', params: reply_params.merge(body: '') }

        it 'returns a validation failure' do
          expect(response).to have_http_status(:unprocessable_content)
        end

        it 'keeps the original message' do
          expect(conversation.messages.count).to eq 1
        end
      end
    end

    context 'when the recipient has blocked the sender' do
      before { recipient.blocks.create!(blocked: member) }

      it 'does not deliver a message' do
        expect { post '/messages', params: }.not_to change(Mailboxer::Message, :count)
      end

      it 'explains why the message was rejected' do
        post '/messages', params: params
        expect(flash[:error]).to include('has blocked you')
      end
    end
  end

  describe 'the conversation about a topic' do
    let(:conversation) do
      receipt = member.send_message(recipient, 'Could I have some?', subject_line)
      receipt.notification.update(notified_object: topic)
      receipt.conversation
    end

    before do
      sign_in recipient
      get conversation_path(conversation)
    end

    context 'when topic is a seed' do
      let(:topic) { seed }

      it { expect(response.body).to include("About") }
      it { expect(response.body).to include(seed_path(seed)) }
      it { expect(response.body).to include(seed.to_s) }
    end

    context 'when topic is another notified object' do
      let(:topic) { create(:planting) }

      it { expect(response.body).to include("About") }
      it { expect(response.body).to include(planting_path(topic)) }
      it { expect(response.body).to include(topic.to_s) }
    end
  end
end
