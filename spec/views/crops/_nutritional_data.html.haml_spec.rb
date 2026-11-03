# frozen_string_literal: true

require 'rails_helper'

describe 'crops/_nutritional_data' do
  subject { rendered }

  let(:crop) { build_stubbed(:crop) }
  let(:nutritional_data) do
    double(
      'AustralianFoodClassificationData',
      food_name: 'Tomato, raw',
      public_food_key: 'F008558',
      energy_with_dietary_fibre_equated_kj: 85.0,
      protein_g: 0.9,
      fat_total_g: 0.2,
      available_carbohydrate_with_sugar_alcohols_g: 2.8,
      total_sugars_g: 2.5,
      total_dietary_fibre_g: 1.5,
      sodium_na_mg: 5.0
    )
  end

  before do
    allow(crop).to receive(:australian_food_classification_data).and_return(nutritional_data)
    render partial: 'crops/nutritional_data', locals: { crop: }
  end

  it 'renders the localized section heading' do
    expect(rendered).to have_css('h2', text: I18n.t('crops.nutritional_data.title'))
  end

  it 'renders the localized summary sentence' do
    expected_text = I18n.t('crops.nutritional_data.summary', food_name: 'Tomato, raw')
    expect(rendered).to have_content(expected_text)
  end

  it 'renders the localized energy row' do
    expect(rendered).to have_css('th', text: I18n.t('crops.nutritional_data.energy'))
  end

  it 'renders the localized protein row' do
    expect(rendered).to have_css('th', text: I18n.t('crops.nutritional_data.protein'))
  end

  it 'renders the localized fat total row' do
    expect(rendered).to have_css('th', text: I18n.t('crops.nutritional_data.fat_total'))
  end

  it 'renders the localized carbohydrate row' do
    expect(rendered).to have_css('th', text: I18n.t('crops.nutritional_data.carbohydrate'))
  end

  it 'renders the localized sugars row' do
    expect(rendered).to have_css('th', text: I18n.t('crops.nutritional_data.sugars'))
  end

  it 'renders the localized fibre row' do
    expect(rendered).to have_css('th', text: I18n.t('crops.nutritional_data.fibre'))
  end

  it 'renders the localized sodium row' do
    expect(rendered).to have_css('th', text: I18n.t('crops.nutritional_data.sodium'))
  end

  it 'renders the localized see more link' do
    expect(rendered).to have_link(
      I18n.t('crops.nutritional_data.see_more'),
      href: 'https://www.foodstandards.gov.au/science-data/food-nutrient-databases/afcd/search/food/F008558'
    )
  end

  context 'when there is no nutritional data' do
    let(:nutritional_data) { nil }

    it 'renders nothing' do
      expect(rendered).to be_blank
    end
  end
end
