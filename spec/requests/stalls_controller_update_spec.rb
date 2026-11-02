# frozen_string_literal: true

require 'rails_helper'

describe StallsController, '#update', flipper: :garden_stall do
  let(:owner) { create(:member) }
  let!(:stall) { create(:stall, :open, member: owner) }

  context 'when the owner changes who can claim' do
    before do
      sign_in owner
      patch stall_path, params: { stall: { claim_area: 'anywhere', postage: '1' } }
    end

    it 'sets where friends can be' do
      expect(stall.reload).to be_anywhere
    end

    it 'sets that they may be asked for postage' do
      expect(stall.reload).to be_postage
    end
  end

  context 'with an area that is not one' do
    before do
      sign_in owner
      patch stall_path, params: { stall: { claim_area: 'moon' } }
    end

    it 'leaves the stall alone' do
      expect(stall.reload).to be_region
    end
  end
end
