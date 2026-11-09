# frozen_string_literal: true

require 'rails_helper'

describe 'pages/about.html.haml' do
  it 'renders the title and heading in English' do
    render
    expect(view.content_for(:title)).to eq 'About'
    expect(rendered).to have_css 'h1', text: 'About'
    expect(rendered).to have_link 'GitHub page', href: 'https://github.com/Growstuff/growstuff'
  end

  %i(de es fr ja zh).each do |locale|
    context "with locale #{locale}" do
      it 'renders translated title and links' do
        I18n.with_locale(locale) do
          render
          expect(view.content_for(:title)).to eq I18n.t('pages.about.title')
          expect(rendered).to have_css 'h1', text: I18n.t('pages.about.title')
          expect(rendered).to have_link I18n.t('pages.about.github_page'), href: 'https://github.com/Growstuff/growstuff'
        end
      end
    end
  end
end
