# frozen_string_literal: true

require 'rails_helper'

feature 'GitHub Releases', :vcr do
  scenario 'Viewing the releases widget on the homepage' do
    visit root_path
    expect(page).to have_content('Recent Releases')
    expect(page).to have_link('Find out more »', href: 'https://github.com/Growstuff/growstuff/releases')
  end
end
