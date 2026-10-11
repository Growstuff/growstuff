# frozen_string_literal: true

require 'rails_helper'

describe "footer" do
  before { visit root_path }

  it "footer is on home page" do
    expect(page).to have_css 'footer'
  end

  it 'has the Open Service link and graphic' do
    expect(page).to have_css 'a[href="https://opendefinition.org/ossd/"]'
  end

  it 'links to the policies and help pages' do
    within 'footer' do
      expect(page).to have_link 'Terms Of Service', href: '/policy/tos'
      expect(page).to have_link 'Privacy Policy', href: '/policy/privacy'
      expect(page).to have_link 'Data Use Policy', href: '/policy/api'
      expect(page).to have_link 'Community Guidelines', href: '/policy/community'
      expect(page).to have_link 'Support', href: '/support'
      expect(page).to have_link 'Contact', href: '/about/contact'
    end
  end
end
