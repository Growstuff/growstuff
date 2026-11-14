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

  context 'when the planting has a short code' do
    let(:planting) { build(:planting, short_code: 'ab12') }
    let(:heat_so_far) { nil }
    let(:heat_needed) { nil }

    it 'explains it can be written on a plant label' do
      expect(rendered).to have_css '.plantingshortcode--help[data-bs-content*="plant label"]'
    end
  end

  context 'when it grew in partial shade' do
    let(:planting) { build(:planting, sunniness: 'semi-shade') }
    let(:heat_so_far) { nil }
    let(:heat_needed) { nil }

    it 'says so in words under the icon' do
      expect(rendered).to have_css '.plantingfact--sunicon-semi-shade'
      expect(rendered).to have_css '.plantingfact--sunniness', text: 'partial shade'
    end
  end
end
