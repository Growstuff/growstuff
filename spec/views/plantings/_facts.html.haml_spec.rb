# frozen_string_literal: true

require 'rails_helper'

describe 'plantings/_facts' do
  let(:planting) { build(:planting) }

  before do
    allow(planting).to receive_messages(heat_so_far:, heat_needed:)
    allow(view).to receive(:can?).and_return(false)
    render partial: 'plantings/facts', locals: { planting: }
  end

  context 'when the heat needed is known' do
    let(:heat_so_far) { 412 }
    let(:heat_needed) { 850 }

    it 'explains that these are not calendar days' do
      expect(rendered).to have_css '.plantingheat--help[data-bs-content*="not calendar days"]'
    end

    it 'shows the heat so far out of what is needed' do
      expect(rendered).to have_css '.plantingheat .plantingfact--heat', text: '412'
      expect(rendered).to have_css '.plantingheat', text: 'of about 850 needed'
    end
  end

  context 'when the heat needed is not known' do
    let(:heat_so_far) { 412 }
    let(:heat_needed) { nil }

    it 'still shows the heat so far' do
      expect(rendered).to have_css '.plantingheat', text: "412 so far; how many it needs isn't known"
    end
  end

  context 'when there is no weather for the planting' do
    let(:heat_so_far) { nil }
    let(:heat_needed) { 850 }

    it 'shows no card' do
      expect(rendered).to have_no_css '.plantingheat'
    end
  end
end
