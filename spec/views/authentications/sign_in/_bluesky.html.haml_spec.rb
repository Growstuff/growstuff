# frozen_string_literal: true

require 'rails_helper'

describe 'authentications/sign_in/_bluesky.html.haml' do
  context 'with default (en) locale' do
    it 'renders the localized label and placeholder' do
      I18n.with_locale(:en) do
        render partial: 'authentications/sign_in/bluesky', locals: { label: 'Sign in with Bluesky' }
        expect(rendered).to have_selector("label[for='handle']", text: I18n.t('authentications.sign_in.bluesky.handle_label'))
        expect(rendered).to have_field('handle', placeholder: I18n.t('authentications.sign_in.bluesky.handle_placeholder'))
      end
    end

    it 'renders the localized terms of service checkbox when tos is true' do
      I18n.with_locale(:en) do
        render partial: 'authentications/sign_in/bluesky', locals: { label: 'Sign in with Bluesky', tos: true }
        expect(rendered).to have_link(I18n.t('authentications.sign_in.bluesky.terms_of_service'), href: '/policy/tos')
        expected_tos = I18n.t('authentications.sign_in.bluesky.agree_to_tos_html', tos_link: I18n.t('authentications.sign_in.bluesky.terms_of_service'))
        expect(rendered).to include(expected_tos)
      end
    end

    it 'omits the terms of service checkbox when tos is false' do
      I18n.with_locale(:en) do
        render partial: 'authentications/sign_in/bluesky', locals: { label: 'Connect to Bluesky', tos: false }
        expect(rendered).to have_no_selector('input#tos_agreement')
      end
    end
  end

  context 'with Japanese (ja) locale' do
    it 'renders Japanese localized labels and terms of service link' do
      I18n.with_locale(:ja) do
        render partial: 'authentications/sign_in/bluesky', locals: { label: 'Blueskyでログイン', tos: true }
        expect(rendered).to have_selector("label[for='handle']", text: I18n.t('authentications.sign_in.bluesky.handle_label'))
        expect(rendered).to have_link(I18n.t('authentications.sign_in.bluesky.terms_of_service'), href: '/policy/tos')
        expected_tos = I18n.t('authentications.sign_in.bluesky.agree_to_tos_html', tos_link: I18n.t('authentications.sign_in.bluesky.terms_of_service'))
        expect(rendered).to include(expected_tos)
      end
    end
  end
end
