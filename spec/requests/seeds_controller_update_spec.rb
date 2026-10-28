# frozen_string_literal: true

require 'rails_helper'

# What a packet says, saved with the seed from its edit dialog.
describe SeedsController, '#update' do
  include Devise::Test::IntegrationHelpers

  let(:seed) { create(:seed) }
  let(:details) do
    { variety: 'Island Bay Italian', batch_number: 'LYIG0403', row_spacing: '50', packet_text: "Approx 15 seeds\nSow by: December 2026" }
  end

  before do
    sign_in seed.owner
    patch seed_path(seed), params: { seed: details }
    seed.reload
  end

  it('saves the variety') { expect(seed.variety).to eq 'Island Bay Italian' }
  it('saves the batch number') { expect(seed.batch_number).to eq 'LYIG0403' }
  it('saves the row spacing') { expect(seed.row_spacing).to eq 50 }
  it('saves the text from the packet') { expect(seed.packet_text).to eq "Approx 15 seeds\nSow by: December 2026" }
end
