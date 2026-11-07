# frozen_string_literal: true

require 'rails_helper'

describe FlickRaw::Response do
  subject(:response) { described_class.new({ 'gift' => { 'eligible_durations' => %w(year month) } }, 'owner') }

  it 'keeps a list of plain strings' do
    expect(response.gift.eligible_durations).to eq %w(year month)
  end
end
