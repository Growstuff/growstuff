# frozen_string_literal: true

require 'rails_helper'

describe 'Signing in and joining as JSON' do
  let(:headers) { { 'ACCEPT' => 'application/json' } }

  describe 'POST /members/sign_in' do
    subject(:sign_in) { post member_session_path, params: { member: { login:, password: } }, headers:, as: :json }

    let(:member) { create(:member) }
    let(:login) { member.login_name }
    let(:password) { member.password }

    context 'with the right password' do
      before { sign_in }

      it { expect(response).to have_http_status(:no_content) }
    end

    context 'with a wrong password' do
      let(:password) { 'nope' }

      before { sign_in }

      it { expect(response).to have_http_status(:unauthorized) }
      it { expect(response.parsed_body['error']).to be_present }
    end
  end

  describe 'POST /members' do
    subject(:join) { post member_registration_path, params: { member: attributes }, headers:, as: :json }

    let(:attributes) do
      { login_name: 'newgrower', email: 'newgrower@example.com', password: 'password1',
        password_confirmation: 'password1', tos_agreement: true }
    end

    context 'with valid details' do
      it { expect { join }.to change(Member, :count).by(1) }

      it 'says where to go next' do
        join
        expect(response.parsed_body['location']).to be_present
      end
    end

    context 'without agreeing to the terms' do
      let(:attributes) { super().merge(tos_agreement: false) }

      before { join }

      it { expect(response).to have_http_status(:unprocessable_entity) }
      it { expect(response.parsed_body['errors']).to have_key('tos_agreement') }
    end

    context 'when the captcha fails' do
      before do
        allow_any_instance_of(RegistrationsController).to receive(:verify_recaptcha).and_return(false) # rubocop:disable RSpec/AnyInstance
        join
      end

      it { expect(response).to have_http_status(:unprocessable_entity) }
      it { expect { join }.not_to change(Member, :count) }
    end
  end
end
