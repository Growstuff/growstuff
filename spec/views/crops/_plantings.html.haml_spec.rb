# frozen_string_literal: true

require 'rails_helper'

describe 'crops/_plantings' do
  subject { rendered }

  let(:crop) { create(:crop) }

  context 'when nobody has planted the crop' do
    context 'when signed out' do
      before do
        allow(view).to receive(:current_member).and_return(nil)
        render partial: 'crops/plantings', locals: { crop: }
      end

      it 'renders the localized empty message' do
        expect(rendered).to have_content(I18n.t('crops.plantings.empty'))
      end

      it 'renders the signin prompt to track plantings' do
        expect(rendered).to have_content(I18n.t('crops.plantings.track_plantings', crop: crop.name))
      end
    end

    context 'when signed in' do
      let(:member) { create(:member) }

      before do
        allow(view).to receive(:current_member).and_return(member)
        render partial: 'crops/plantings', locals: { crop: }
      end

      it 'renders the localized empty message' do
        expect(rendered).to have_content(I18n.t('crops.plantings.empty'))
      end

      it 'renders the localized plant crop button' do
        expect(rendered).to have_content(I18n.t('crops.plantings.plant_crop', crop: crop.name))
      end
    end
  end

  context 'when plantings exist for the crop' do
    let(:member) { create(:member) }
    let(:garden) { create(:garden, owner: member) }
    let!(:planting) { create(:planting, crop:, owner: member, garden:) }

    before do
      allow(view).to receive(:current_member).and_return(member)
      render partial: 'crops/plantings', locals: { crop: }
    end

    it 'renders the planting owner name' do
      expect(rendered).to have_content(member.login_name)
    end

    it 'renders the garden name' do
      expect(rendered).to have_content(garden.name)
    end
  end
end
