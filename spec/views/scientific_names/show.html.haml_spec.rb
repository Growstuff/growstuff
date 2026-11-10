# frozen_string_literal: true

require 'rails_helper'

describe 'scientific_names/show.html.haml' do
  subject { rendered }

  let(:crop) { create(:crop, name: 'Tomato') }
  let(:scientific_name) { create(:scientific_name, crop: crop, name: 'Solanum lycopersicum') }

  before do
    enable_can
    assign(:scientific_name, scientific_name)
    render
  end

  it 'renders the localized scientific name label' do
    expect(rendered).to have_content(I18n.t('scientific_names.show.scientific_name_label'))
  end

  it 'renders the localized crop label' do
    expect(rendered).to have_content(I18n.t('scientific_names.show.crop_label'))
  end

  it 'renders the localized back link' do
    expect(rendered).to have_link(I18n.t('scientific_names.show.back'), href: scientific_names_path)
  end
end
