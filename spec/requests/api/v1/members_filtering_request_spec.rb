# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API member filtering' do
  include_context 'with an API member'

  let!(:member) { create(:member) }
  let!(:other_member) { create(:member) }

  def ids
    json['data'].pluck('id')
  end

  context 'with filter[slug]' do
    before { get "/api/v1/members?filter[slug]=#{member.slug}", headers: read_headers }

    it { expect(ids).to eq([member.id.to_s]) }
  end

  context 'with filter[login-name]' do
    before { get "/api/v1/members?filter[login-name]=#{other_member.login_name}", headers: read_headers }

    it { expect(ids).to eq([other_member.id.to_s]) }
  end

  context 'with a member\'s attributes' do
    before do
      token
      get "/api/v1/members/#{member.id}", headers: read_headers
    end

    it 'does not expose the email address' do
      expect(response.body).not_to include(member.email)
    end

    it 'does not expose the API token' do
      expect(response.body).not_to include(token)
    end
  end
end
