# frozen_string_literal: true

require 'rails_helper'

describe 'gardens/_card' do
  let(:owner) { create(:member) }
  let(:garden) { create(:garden, owner:) }

  before do
    controller.stub(:current_user) { owner }
    allow(view).to receive_messages(member_signed_in?: true, current_member: owner)
  end

  context 'when rendered without an assigned @owner' do
    it 'displays the owner prefix and renders the member' do
      render partial: 'gardens/card', locals: { garden: }
      expect(rendered).to have_content(I18n.t('gardens.card.owner'))
    end
  end

  context 'when rendered with an assigned @owner' do
    before { assign(:owner, owner) }

    it 'omits the owner prefix' do
      render partial: 'gardens/card', locals: { garden: }
      expect(rendered).to have_no_content(I18n.t('gardens.card.owner'))
    end
  end

  context 'when the garden has no plantings' do
    before { render partial: 'gardens/card', locals: { garden: } }

    it 'displays the no perennial plantings text' do
      expect(rendered).to have_content(I18n.t('gardens.card.no_perennials'))
    end

    it 'displays the no annual plantings text' do
      expect(rendered).to have_content(I18n.t('gardens.card.no_annuals'))
    end

    it 'renders the layout link with localized button and screen reader text' do
      expect(rendered).to have_css('.garden-card-layout-button', text: /#{I18n.t('gardens.card.layout')}/)
    end
  end

  context 'when the garden has perennial plantings' do
    let(:crop) { create(:crop, perennial: true) }
    let!(:perennial_planting) { create(:planting, garden:, owner:, crop:) }

    it 'displays the perennials heading' do
      render partial: 'gardens/card', locals: { garden: }
      expect(rendered).to have_content(I18n.t('gardens.card.perennials'))
    end
  end

  context 'in another locale' do
    it 'translates strings according to the active locale' do
      I18n.with_locale(:es) do
        render partial: 'gardens/card', locals: { garden: }
        expect(rendered).to have_content(I18n.t('gardens.card.no_perennials', locale: :es))
      end
    end
  end
end
