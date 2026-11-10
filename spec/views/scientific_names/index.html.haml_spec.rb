# frozen_string_literal: true

require 'rails_helper'

describe 'scientific_names/index.html.haml' do
  subject { rendered }

  let(:crop) { create(:crop, name: 'Tomato') }
  let(:scientific_name) { create(:scientific_name, crop: crop, name: 'Solanum lycopersicum') }

  before do
    enable_can
    assign(:scientific_names, [scientific_name].paginate(page: 1, per_page: 10))
    render
  end

  it 'renders the localized index title' do
    expect(view.content_for(:title)).to eq(I18n.t('scientific_names.index.title'))
  end

  it 'renders the localized table headers' do
    expect(rendered).to have_content(I18n.t('scientific_names.index.scientific_name'))
    expect(rendered).to have_content(I18n.t('scientific_names.index.crop'))
  end

  it 'renders the localized show link' do
    expect(rendered).to have_link(I18n.t('scientific_names.index.show'), href: scientific_name_path(scientific_name))
  end
end
