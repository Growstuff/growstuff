# frozen_string_literal: true

require 'rails_helper'

describe RegistrationsController, '#edit' do
  let(:member) { create(:member, label_width_mm: '62', label_height_mm: '29') }
  let(:page) { Capybara.string(response.body) }

  before do
    sign_in member
    get edit_member_registration_path
  end

  it 'shows the saved width' do
    expect(page).to have_css('input[name="member[label_width_mm]"][value="62"]')
  end

  it 'shows the saved height' do
    expect(page).to have_css('input[name="member[label_height_mm]"][value="29"]')
  end

  it 'offers common label sizes' do
    expect(page).to have_css('[data-label-size-preset] option[value="62x29"]', visible: :all)
  end
end
