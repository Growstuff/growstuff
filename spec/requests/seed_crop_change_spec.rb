# frozen_string_literal: true

require 'rails_helper'

describe 'changing the crop of a seed' do
  let(:owner) { create(:member) }
  let(:old_crop) { create(:crop) }
  let(:new_crop) { create(:crop) }
  let(:seed) { create(:seed, owner:, crop: old_crop) }

  before do
    sign_in owner
    patch seed_path(seed), params: { seed: { crop_id: new_crop.id } }
  end

  context 'with a planting grown from it' do
    let(:seed) { create(:seed, owner:, crop: old_crop).tap { |s| create(:planting, owner:, crop: old_crop, parent_seed: s) } }

    it { expect(response).to redirect_to(seed_crop_change_path(seed, from: old_crop.id)) }
  end

  context 'without anything grown from it' do
    it { expect(response).to redirect_to(seed_path(seed, anchor: 'facts')) }
  end
end
