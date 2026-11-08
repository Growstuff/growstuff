# frozen_string_literal: true

require 'rails_helper'

describe 'crops/_growing_facts' do
  let(:crop) { build_stubbed(:crop, sow_months: [9, 10, 11]) }

  before do
    allow(view).to receive(:growing_facts).and_return([])
    allow(view).to receive(:sow_months_text).with([9, 10, 11]).and_return('Sep–Nov')
    allow(view).to receive(:sow_months_text).with(crop.sow_months_northern).and_return('Mar–May')
    render partial: 'crops/growing_facts', locals: { crop: }
  end

  it 'shows the when to sow header' do
    expect(rendered).to have_css('h3', text: I18n.t('crops.growing_facts.when_to_sow'))
  end

  it 'shows the southern hemisphere label' do
    expect(rendered).to have_css('.crop-sow-hemisphere small', text: I18n.t('crops.growing_facts.southern_hemisphere'))
  end

  it 'shows the northern hemisphere label' do
    expect(rendered).to have_css('.crop-sow-hemisphere small', text: I18n.t('crops.growing_facts.northern_hemisphere'))
  end
end
