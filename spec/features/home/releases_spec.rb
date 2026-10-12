# frozen_string_literal: true

require 'rails_helper'

feature 'GitHub Releases' do
  scenario 'Viewing the releases page' do
    visit releases_path
    expect(page).to have_link('Find out more »', href: 'https://github.com/Growstuff/growstuff/releases')
  end

  scenario 'The homepage no longer carries the releases' do
    visit root_path
    expect(page).to have_no_link('Find out more »')
  end
end
