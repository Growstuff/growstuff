# frozen_string_literal: true

require 'rails_helper'

describe 'plantings/_progress_ring' do
  let(:planting) { build(:planting) }

  before do
    allow(planting).to receive_messages(percentage_grown:, progress_state: :growing)
    render partial: 'plantings/progress_ring', locals: { planting: }
  end

  context 'when part way' do
    let(:percentage_grown) { 48.4 }

    it 'fills that much of the ring and says the percentage' do
      expect(rendered).to have_css '.progress-ring[aria-valuenow="48"]'
      expect(rendered).to have_css '.progress-ring__arc.progress-ring--growing[stroke-dasharray="48.4 100"]'
      expect(rendered).to have_css '.plantingfact--progress', text: '48%'
    end
  end

  context 'when it has run past its finish' do
    let(:percentage_grown) { 130.0 }

    it 'stops the ring at full but still says how far past' do
      expect(rendered).to have_css '.progress-ring__arc[stroke-dasharray="100 100"]'
      expect(rendered).to have_css '.plantingfact--progress', text: '130%'
    end
  end
end
