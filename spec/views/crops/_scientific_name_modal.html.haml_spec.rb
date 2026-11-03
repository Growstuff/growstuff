# frozen_string_literal: true

require 'rails_helper'

describe 'crops/_scientific_name_modal' do
  subject { rendered }

  let(:crop) { create(:crop, name: 'Potato') }

  context 'when scientific name is a new record' do
    let(:scientific_name) { ScientificName.new(crop: crop) }

    before do
      render partial: 'crops/scientific_name_modal', locals: { crop:, scientific_name: }
    end

    it 'renders the localized add title' do
      expect(rendered).to have_content(I18n.t('crops.scientific_name_modal.add_title', crop: crop.name))
    end

    it 'renders the localized close button label' do
      expect(rendered).to have_css("button.btn-close[aria-label='#{I18n.t('crops.scientific_name_modal.close')}']")
    end

    it 'renders the localized name label' do
      expect(rendered).to have_content(I18n.t('crops.scientific_name_modal.name'))
    end

    it 'renders the localized gbif key label' do
      expect(rendered).to have_content(I18n.t('crops.scientific_name_modal.gbif_key'))
    end

    it 'renders the localized gbif hint' do
      expect(rendered).to have_content(I18n.t('crops.scientific_name_modal.gbif_hint'))
    end

    it 'renders the localized wikidata id label' do
      expect(rendered).to have_content(I18n.t('crops.scientific_name_modal.wikidata_id'))
    end

    it 'renders the localized cancel button' do
      expect(rendered).to have_content(I18n.t('crops.scientific_name_modal.cancel'))
    end

    it 'renders the localized save submit button' do
      expect(rendered).to have_button(I18n.t('crops.scientific_name_modal.save'))
    end
  end

  context 'when scientific name is persisted' do
    let(:scientific_name) { create(:scientific_name, crop: crop, name: 'Solanum tuberosum') }

    before do
      render partial: 'crops/scientific_name_modal', locals: { crop:, scientific_name: }
    end

    it 'renders the localized edit title' do
      expect(rendered).to have_content(I18n.t('crops.scientific_name_modal.edit_title'))
    end

    it 'renders the localized close button label' do
      expect(rendered).to have_css("button.btn-close[aria-label='#{I18n.t('crops.scientific_name_modal.close')}']")
    end

    it 'renders the localized name label' do
      expect(rendered).to have_content(I18n.t('crops.scientific_name_modal.name'))
    end

    it 'renders the localized gbif key label' do
      expect(rendered).to have_content(I18n.t('crops.scientific_name_modal.gbif_key'))
    end

    it 'renders the localized gbif hint' do
      expect(rendered).to have_content(I18n.t('crops.scientific_name_modal.gbif_hint'))
    end

    it 'renders the localized wikidata id label' do
      expect(rendered).to have_content(I18n.t('crops.scientific_name_modal.wikidata_id'))
    end

    it 'renders the localized cancel button' do
      expect(rendered).to have_content(I18n.t('crops.scientific_name_modal.cancel'))
    end

    it 'renders the localized save submit button' do
      expect(rendered).to have_button(I18n.t('crops.scientific_name_modal.save'))
    end
  end
end
