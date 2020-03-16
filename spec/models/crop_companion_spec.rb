# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CropCompanion, type: :model do
  it 'has a crop' do
    cc = described_class.new
    cc.crop_a = FactoryBot.create :tomato
    cc.crop_b = FactoryBot.create :maize
    cc.save!

    expect(cc.crop_a.name).to eq 'tomato'
  end
end
