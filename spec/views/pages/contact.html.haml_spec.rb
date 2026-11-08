# frozen_string_literal: true

require 'rails_helper'

describe 'pages/contact.html.haml' do
  subject { rendered }

  context 'in default English locale' do
    before do
      I18n.with_locale(:en) do
        render
      end
    end

    it 'sets the page title' do
      expect(view.content_for(:title)).to eq('Contact')
    end

    it 'shows contact details and headings' do
      expect(rendered).to have_css('h1', text: 'Contact')
      expect(rendered).to have_content('General contact email')
      expect(rendered).to have_link('info@growstuff.org', href: 'mailto:info@growstuff.org')
      expect(rendered).to have_link('support@growstuff.org', href: 'mailto:support@growstuff.org')
      expect(rendered).to have_link('media@growstuff.org', href: 'mailto:media@growstuff.org')
      expect(rendered).to have_link('FAQ', href: '/support')
      expect(rendered).to have_link('@growstufforg', href: 'http://twitter.com/growstufforg')
    end
  end

  context 'in German locale' do
    before do
      I18n.with_locale(:de) do
        render
      end
    end

    it 'sets the localized page title' do
      expect(view.content_for(:title)).to eq('Kontakt')
    end

    it 'shows localized headings and labels' do
      expect(rendered).to have_css('h1', text: 'Kontakt')
      expect(rendered).to have_content('Allgemeine Kontakt-E-Mail')
      expect(rendered).to have_content('Medien-/Presseanfragen')
    end
  end
end
