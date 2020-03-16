# frozen_string_literal: true

require 'rails_helper'

describe "crop wrangling button" do
  context 'not signed in' do
    before { visit crops_path }
    it { expect(page).to have_no_link "Wrangle Crops", href: wrangle_crops_path }
  end

  context "signed in, but not a crop wrangler" do
    include_context 'signed in member'
    before { visit crops_path }
    it { expect(page).to have_no_link "Wrangle Crops", href: wrangle_crops_path }
  end

  context "signed in crop wrangler" do
    include_context 'signed in crop wrangler'
    before { visit crops_path }
    it { expect(page).to have_link "Wrangle Crops", href: wrangle_crops_path }
  end
end
