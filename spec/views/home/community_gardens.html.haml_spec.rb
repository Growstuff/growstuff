# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'home/community_gardens.html.haml' do
  before do
    allow(view).to receive_messages(current_member: nil, member_signed_in?: false)
  end

  context 'with default (en) locale' do
    it 'renders localized feature bullet points' do
      I18n.with_locale(:en) do
        render
        expect(rendered).to include(CGI.escapeHTML(I18n.t('community_gardens.features.track_plantings_and_harvests')))
        expect(rendered).to include(CGI.escapeHTML(I18n.t('community_gardens.features.keep_notes')))
        expect(rendered).to include(CGI.escapeHTML(I18n.t('community_gardens.features.add_collaborators')))
        expect(rendered).to include(CGI.escapeHTML(I18n.t('community_gardens.features.see_other_gardens')))
        expect(rendered).to include(CGI.escapeHTML(I18n.t('community_gardens.features.get_advice_and_support')))
        expect(rendered).to include(CGI.escapeHTML(I18n.t('community_gardens.sign_up')))
      end
    end
  end

  context 'with Japanese (ja) locale' do
    it 'renders localized Japanese feature bullet points' do
      I18n.with_locale(:ja) do
        render
        expect(rendered).to include(I18n.t('community_gardens.features.track_plantings_and_harvests'))
        expect(rendered).to include(I18n.t('community_gardens.features.keep_notes'))
        expect(rendered).to include(I18n.t('community_gardens.features.add_collaborators'))
        expect(rendered).to include(I18n.t('community_gardens.features.see_other_gardens'))
        expect(rendered).to include(I18n.t('community_gardens.features.get_advice_and_support'))
        expect(rendered).to include(I18n.t('community_gardens.sign_up'))
      end
    end
  end
end
