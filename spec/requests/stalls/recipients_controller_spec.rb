# frozen_string_literal: true

require 'rails_helper'

describe Stalls::RecipientsController, flipper: :garden_stall do
  let(:member) { create(:member) }
  let!(:sam) { create(:member, login_name: 'SamOkafor') }

  before { sign_in member }

  describe 'GET /stall/recipients' do
    before { get stall_recipients_path, params: { q: 'okafor' } }

    it 'finds members by name' do
      expect(response.parsed_body.pluck('name')).to eq ['SamOkafor']
    end

    it 'does not offer the signed-in member' do
      get stall_recipients_path, params: { q: member.login_name }
      expect(response.parsed_body).to be_empty
    end

    it 'finds nobody for a single letter' do
      get stall_recipients_path, params: { q: 's' }
      expect(response.parsed_body).to be_empty
    end
  end

  context 'when signed out' do
    before { sign_out member }

    it 'asks them to sign in' do
      get stall_recipients_path, params: { q: 'sam' }
      expect(response).to redirect_to(new_member_session_path)
    end
  end
end
