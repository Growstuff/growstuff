# frozen_string_literal: true

require 'rails_helper'

describe 'crops/_find_seeds' do
  subject { rendered }

  let(:crop) { create(:crop, approval_status: 'approved') }

  context 'when crop has no seeds' do
    before do
      render partial: 'crops/find_seeds', locals: { crop: }
    end

    it 'renders the localized empty message' do
      expect(rendered).to have_content(I18n.t('crops.find_seeds.empty'))
    end

    it 'renders the link to purchase seeds via ebay' do
      expect(rendered).to have_content(I18n.t('crops.find_seeds.purchase_via_ebay'))
    end
  end

  context 'when crop has tradable seeds' do
    let(:member) { create(:member) }
    let!(:seed) { create(:seed, crop:, member:, tradable_to: 'locally') }

    before do
      render partial: 'crops/find_seeds', locals: { crop: }
    end

    it 'renders the localized trade offer' do
      expected = I18n.t('crops.find_seeds.will_trade', owner: seed.owner, tradable_to: seed.tradable_to)
      expect(rendered).to have_content(expected)
    end

    it 'renders the localized view all seeds link' do
      expected = I18n.t('crops.find_seeds.view_all', crop: crop.name)
      expect(rendered).to have_content(expected)
    end
  end

  context 'when user is signed in' do
    let(:current_member) { create(:member) }

    before do
      allow(view).to receive_messages(member_signed_in?: true, current_member:)
      render partial: 'crops/find_seeds', locals: { crop: }
    end

    it 'renders the link to list seeds to trade' do
      expected = I18n.t('crops.find_seeds.list_seeds', crop: crop.name)
      expect(rendered).to have_content(expected)
    end
  end

  context 'when user is not signed in' do
    before do
      allow(view).to receive_messages(member_signed_in?: false, current_member: nil)
      render partial: 'crops/find_seeds', locals: { crop: }
    end

    it 'renders the signin/signup prompt with localized action' do
      expected = I18n.t('crops.find_seeds.trade_seeds')
      expect(rendered).to have_content(expected)
    end
  end
end
