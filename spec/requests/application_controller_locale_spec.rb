# frozen_string_literal: true

require 'rails_helper'

describe ApplicationController, 'locale selection' do
  let(:member) { create(:member) }

  after do
    I18n.locale = I18n.default_locale
  end

  context 'without a logged-in member' do
    it 'defaults to I18n.default_locale' do
      get root_path
      expect(I18n.locale).to eq(:en)
    end

    it 'swaps to locale specified in params' do
      get root_path, params: { locale: 'es' }
      expect(I18n.locale).to eq(:es)
    end
  end

  context 'with a logged-in member without a preferred locale' do
    before { sign_in member }

    it 'defaults to I18n.default_locale' do
      get root_path
      expect(I18n.locale).to eq(:en)
    end

    it 'allows overriding via params[:locale]' do
      get root_path, params: { locale: 'fr' }
      expect(I18n.locale).to eq(:fr)
    end
  end

  context 'with a logged-in member with a non-en preferred locale' do
    before do
      member.update(locale: 'es')
      sign_in member
    end

    it 'swaps application context to the member preferred locale' do
      get root_path
      expect(I18n.locale).to eq(:es)
    end

    it 'allows overriding member preferred locale via params[:locale]' do
      get root_path, params: { locale: 'de' }
      expect(I18n.locale).to eq(:de)
    end
  end

  context 'when updating locale via profile edit' do
    before { sign_in member }

    it 'persists chosen locale and switches context' do
      put member_registration_path, params: { member: { locale: 'de' } }
      expect(member.reload.locale).to eq('de')
    end
  end
end
