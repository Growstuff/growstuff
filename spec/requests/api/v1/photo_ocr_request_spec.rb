# frozen_string_literal: true

require 'rails_helper'

# The text read from a label photo is saved by the OCR script, with an admin's token.
RSpec.describe 'Writing the text from a label photo' do
  include_context 'with an API member'

  let(:owner) { create(:member) }
  let(:photo) { create(:photo, owner:) }
  let(:text) { "Approx 15 seeds per packet\nSow by: December 2026" }
  let(:attributes) { { 'ocr-text' => text, 'ocr-engine' => 'tesseract-5.3', 'ocr-at' => '2026-10-31T01:00:00Z' } }

  def write(attributes, headers: auth_headers)
    patch "/api/v1/photos/#{photo.id}", params: { data: { type: 'photos', id: photo.id.to_s, attributes: } }.to_json, headers:
  end

  context 'with an admin, whose photo it is not' do
    let(:member) { create(:admin_member) }

    before { write(attributes) }

    it('is saved') { expect(response).to have_http_status(:ok) }
    it('puts the text on the photo') { expect(photo.reload.ocr_text).to eq text }
    it('puts the engine on the photo') { expect(photo.reload.ocr_engine).to eq 'tesseract-5.3' }
    it('puts the time on the photo') { expect(photo.reload.ocr_at).to eq Time.utc(2026, 10, 31, 1) }
    it('shows the text in the response') { expect(json['data']['attributes']['ocr-text']).to eq text }
  end

  context 'with the member whose photo it is' do
    let(:member) { owner }

    before { write(attributes) }

    it('is forbidden') { expect(response).to have_http_status(:forbidden) }
    it('is not saved') { expect(photo.reload.ocr_text).to be_nil }
  end

  context 'with another member' do
    before { write(attributes) }

    it('is forbidden') { expect(response).to have_http_status(:forbidden) }
    it('is not saved') { expect(photo.reload.ocr_text).to be_nil }
  end

  context 'with no token' do
    before { write(attributes, headers: write_headers) }

    it('is unauthorised') { expect(response).to have_http_status(:unauthorized) }
  end

  context 'with an admin changing the title' do
    let(:member) { create(:admin_member) }

    before { write({ 'title' => 'a new title' }) }

    it('is not saved') { expect(photo.reload.title).not_to eq 'a new title' }
  end
end
