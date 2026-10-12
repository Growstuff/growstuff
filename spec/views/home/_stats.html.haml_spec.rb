# frozen_string_literal: true

require 'rails_helper'

describe 'home/_stats.html.haml', type: "view" do
  before { render }

  it 'counts gardeners' do
    expect(rendered).to have_content "0 gardeners"
  end

  it 'counts plantings' do
    expect(rendered).to have_content "0 plantings"
  end

  it 'counts crops' do
    expect(rendered).to have_content "0 crops"
  end
end
