# frozen_string_literal: true

require 'rails_helper'

describe 'harvests/_edit_modal' do
  subject { rendered }

  let(:harvest) { create(:harvest) }

  before do
    render partial: 'harvests/edit_modal', locals: { harvest: }
  end

  it 'renders the localized modal title' do
    expect(rendered).to have_content(I18n.t('harvests.edit_modal.title', crop: harvest.crop.name))
  end

  it 'renders the localized harvested_at label' do
    expect(rendered).to have_content(I18n.t('harvests.edit_modal.harvested_at'))
  end

  it 'renders the localized plant_part label' do
    expect(rendered).to have_content(I18n.t('harvests.edit_modal.plant_part'))
  end

  it 'renders the localized quantity label' do
    expect(rendered).to have_content(I18n.t('harvests.edit_modal.quantity'))
  end

  it 'renders the localized unit label' do
    expect(rendered).to have_content(I18n.t('harvests.edit_modal.unit'))
  end

  it 'renders the localized weight_quantity label' do
    expect(rendered).to have_content(I18n.t('harvests.edit_modal.weight_quantity'))
  end

  it 'renders the localized weight_unit label' do
    expect(rendered).to have_content(I18n.t('harvests.edit_modal.weight_unit'))
  end

  it 'renders the localized notes label' do
    expect(rendered).to have_content(I18n.t('harvests.edit_modal.notes'))
  end
end
