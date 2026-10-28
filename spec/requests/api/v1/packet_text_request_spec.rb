# frozen_string_literal: true

require 'rails_helper'

# The text read from a seed packet's photos is saved by the OCR script, with an admin's token.
RSpec.describe 'Writing the text from a seed packet' do
  include_context 'with an API member'

  let(:owner) { create(:member) }
  let(:seed) { create(:seed, owner:) }
  let(:text) { "Approx 15 seeds per packet\nSow by: December 2026" }

  def write(attributes, headers: auth_headers)
    patch "/api/v1/seeds/#{seed.id}", params: { data: { type: 'seeds', id: seed.id.to_s, attributes: } }.to_json, headers:
  end

  context 'with an admin, whose seed it is not' do
    let(:member) { create(:admin_member) }

    before { write({ 'packet-text' => text }) }

    it('is saved') { expect(response).to have_http_status(:ok) }
    it('is on the seed') { expect(seed.reload.packet_text).to eq text }
    it('is not shown in the response') { expect(json['data']['attributes']).not_to have_key('packet-text') }
  end

  context 'with the member whose seed it is' do
    let(:member) { owner }

    before { write({ 'packet-text' => text }) }

    it('is forbidden') { expect(response).to have_http_status(:forbidden) }
    it('is not saved') { expect(seed.reload.packet_text).to be_nil }
  end

  context 'with another member' do
    before { write({ 'packet-text' => text }) }

    it('is forbidden') { expect(response).to have_http_status(:forbidden) }
    it('is not saved') { expect(seed.reload.packet_text).to be_nil }
  end

  context 'with no token' do
    before { write({ 'packet-text' => text }, headers: write_headers) }

    it('is unauthorised') { expect(response).to have_http_status(:unauthorized) }
  end

  context 'when the member whose seed it is changes something else' do
    let(:member) { owner }

    before { write({ 'quantity' => 40 }) }

    it('is saved') { expect(response).to have_http_status(:ok) }
    it('is on the seed') { expect(seed.reload.quantity).to eq 40 }
  end
end
