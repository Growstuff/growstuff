# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CropCompanion do
  it 'has a crop' do
    cc = described_class.new
    cc.crop_a = create :tomato
    cc.crop_b = create :maize
    cc.save!

    expect(cc.crop_a.name).to eq 'tomato'
  end
end
