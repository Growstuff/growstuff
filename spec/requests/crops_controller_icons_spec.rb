# frozen_string_literal: true

require 'rails_helper'

describe CropsController do
  let(:tomato) { create(:crop, name: 'tomato') }

  describe 'crop icons: GET /crops/:slug.svg' do
    it "serves the icon chosen for the crop" do
      tomato.update!(icon: 'tomato')
      get crop_path(tomato, format: 'svg')

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq 'image/svg+xml'
      expect(response.body).to eq Crop.icon_svg('tomato')
    end

    it 'serves a sprout for a crop with no icon' do
      get crop_path(tomato, format: 'svg')

      expect(response.body).to eq Rails.root.join('app/assets/images/icons/sprout.svg').read
    end
  end

  describe 'crop icons: choosing one' do
    it 'lets a crop wrangler set it from the crop form' do
      sign_in create(:crop_wrangling_member)
      patch crop_path(tomato), params: { crop: { icon: 'tomato' } }

      expect(tomato.reload.icon).to eq 'tomato'
    end

    it 'offers the icons on the crop form' do
      sign_in create(:crop_wrangling_member)
      get edit_crop_path(tomato)

      expect(response.body).to include('<option value="leafy_green">Leafy green</option>')
    end
  end
end
