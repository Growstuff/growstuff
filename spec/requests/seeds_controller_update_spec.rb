# frozen_string_literal: true

require 'rails_helper'

# What a packet says, saved with the seed from its edit dialog.
describe SeedsController, '#update' do
  include Devise::Test::IntegrationHelpers

  let(:seed) { create(:seed) }
  let(:details) do
    { variety: 'Island Bay Italian', batch_number: 'LYIG0403', row_spacing: '50' }
  end

  before do
    sign_in seed.owner
    patch seed_path(seed), params: { seed: details }
    seed.reload
  end

  it('saves the variety') { expect(seed.variety).to eq 'Island Bay Italian' }
  it('saves the batch number') { expect(seed.batch_number).to eq 'LYIG0403' }
  it('saves the row spacing') { expect(seed.row_spacing).to eq 50 }
  it('does not take the text from the packet from a member') do
    patch seed_path(seed), params: { seed: { packet_text: 'typed by a member' } }
    expect(seed.reload.packet_text).to be_nil
  end

  describe 'the sowing facts' do
    before do
      patch seed_path(seed), params: { seed: { sow_months: ['', '10', '11', '2'], how_to_sow: 'Direct sow, 2cm deep.',
                                               germination_days_min: '7', germination_days_max: '14' } }
      seed.reload
    end

    it('saves the months to sow in, once each, in calendar order') { expect(seed.sow_months).to eq [2, 10, 11] }
    it('saves how to sow') { expect(seed.how_to_sow).to eq 'Direct sow, 2cm deep.' }
    it('saves the germination range') { expect([seed.germination_days_min, seed.germination_days_max]).to eq [7, 14] }
  end

  describe 'clearing the months to sow in' do
    let(:seed) { create(:seed, sow_months: [3, 4]) }

    before do
      patch seed_path(seed), params: { seed: { sow_months: [''] } }
      seed.reload
    end

    it('leaves none') { expect(seed.sow_months).to eq [] }
  end
end
