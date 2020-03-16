# frozen_string_literal: true

require 'rails_helper'

describe "footer", js: true do
  before { visit root_path }

  it "footer is on home page" do
    expect(page).to have_css 'footer'
  end

  it 'has the Open Service link and graphic' do
    expect(page).to have_selector 'a[href="https://opendefinition.org/ossd/"]'
  end

  # NB: not testing specific content in the footer since I'm going to put them
  # in the CMS and they'll be variable.
end
