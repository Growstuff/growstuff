# frozen_string_literal: true

require 'rails_helper'

describe 'devise/mailer/confirmation_instructions.html.haml', type: "view" do
  %i[en de es fr ja zh].each do |locale|
    context "with the #{locale} locale" do
      let(:member) { build(:member) }

      before do
        assign(:resource, member)
        assign(:token, 'confirmation-token')
        I18n.with_locale(locale) { render }
      end

      it 'renders the translated confirmation link' do
        expect(rendered).to have_link(I18n.t('devise_views.confirm_account', locale: locale),
                                     href: member_confirmation_url(confirmation_token: 'confirmation-token'))
      end

      it 'preserves the community guidelines link within the translated paragraph' do
        expect(rendered).to have_link(I18n.t('devise_views.guidelines', locale: locale), href: policy_community_url)
      end

      it 'renders the translated greeting' do
        expect(rendered).to have_css('p', text: I18n.t('devise_views.greeting', locale: locale, name: member.login_name))
      end
    end
  end

  context "logged in" do
    before do
      @resource = create(:member)
      render
    end

    it 'has a confirmation link' do
      expect(rendered).to have_content 'Confirm my account'
    end

    it 'has a link to the homepage' do
      expect(rendered).to have_content root_url
    end
  end
end
