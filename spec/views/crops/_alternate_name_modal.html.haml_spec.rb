# frozen_string_literal: true

require 'rails_helper'

describe 'crops/_alternate_name_modal' do
  subject { rendered }

  let(:crop) { create(:crop, name: 'Potato') }

  context 'when alternate name is a new record' do
    let(:alternate_name) { AlternateName.new(crop: crop) }

    before do
      render partial: 'crops/alternate_name_modal', locals: { crop:, alternate_name: }
    end

    it 'renders the localized add title' do
      expect(rendered).to have_content(I18n.t('crops.alternate_name_modal.add_title', crop: crop.name))
    end

    it 'renders the localized close button label' do
      expect(rendered).to have_css("button.btn-close[aria-label='#{I18n.t('crops.alternate_name_modal.close')}']")
    end

    it 'renders the localized name label' do
      expect(rendered).to have_content(I18n.t('crops.alternate_name_modal.name'))
    end

    it 'renders the localized language label' do
      expect(rendered).to have_content(I18n.t('crops.alternate_name_modal.language'))
    end

    it 'renders the localized cancel button' do
      expect(rendered).to have_content(I18n.t('crops.alternate_name_modal.cancel'))
    end

    it 'renders the localized save submit button' do
      expect(rendered).to have_button(I18n.t('crops.alternate_name_modal.save'))
    end
  end

  context 'when alternate name is persisted' do
    let(:alternate_name) { create(:alternate_name, crop: crop, name: 'Spud', language: 'en') }

    before do
      render partial: 'crops/alternate_name_modal', locals: { crop:, alternate_name: }
    end

    it 'renders the localized edit title' do
      expect(rendered).to have_content(I18n.t('crops.alternate_name_modal.edit_title'))
    end

    it 'renders the localized close button label' do
      expect(rendered).to have_css("button.btn-close[aria-label='#{I18n.t('crops.alternate_name_modal.close')}']")
    end

    it 'renders the localized name label' do
      expect(rendered).to have_content(I18n.t('crops.alternate_name_modal.name'))
    end

    it 'renders the localized language label' do
      expect(rendered).to have_content(I18n.t('crops.alternate_name_modal.language'))
    end

    it 'renders the localized cancel button' do
      expect(rendered).to have_content(I18n.t('crops.alternate_name_modal.cancel'))
    end

    it 'renders the localized save submit button' do
      expect(rendered).to have_button(I18n.t('crops.alternate_name_modal.save'))
    end
  end
end
