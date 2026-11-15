# frozen_string_literal: true

require 'rails_helper'

describe "changing a seed's crop" do
  let(:owner) { create(:member) }
  let(:old_crop) { create(:crop) }
  let(:new_crop) { create(:crop) }
  let(:seed) { create(:seed, owner:, crop: new_crop) }
  let!(:planting) { create(:planting, owner:, crop: old_crop, parent_seed: seed) }

  before do
    login_as owner
    visit seed_crop_change_path(seed, from: old_crop.id)
  end

  it { expect(page).to have_link(planting.to_s) }

  context 'when the answer is yes' do
    before do
      click_button 'Yes, change them'
      find('.flash-messages', text: 'Changed to the new crop.')
    end

    it { expect(planting.reload.crop).to eq new_crop }
  end

  context 'when the answer is no' do
    before do
      click_link 'No, leave them'
      find('.seed-show')
    end

    it { expect(planting.reload.crop).to eq old_crop }
  end
end
