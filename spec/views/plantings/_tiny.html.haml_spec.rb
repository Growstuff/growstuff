# frozen_string_literal: true

require 'rails_helper'

describe 'plantings/_tiny' do
  before do
    allow(view).to receive(:crop_icon).and_return('')
    render partial: 'plantings/tiny', locals: { planting: }
  end

  context 'when its parent seed has a variety' do
    let(:planting) { create(:planting, parent_seed: create(:seed, variety: 'Brandywine')) }

    it 'shows the variety in brackets after the name' do
      expect(rendered).to have_css '.crop-chip', text: "#{planting.display_name} (Brandywine)"
    end
  end

  context 'without a parent seed' do
    let(:planting) { create(:planting) }

    it 'shows just the name' do
      expect(rendered).to have_css '.crop-chip', exact_text: planting.display_name
    end
  end
end
