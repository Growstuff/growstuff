# frozen_string_literal: true

require 'rails_helper'

describe CropsHelper do
  describe "display_seed_availability" do
    before do
      @member = create :member
      @crop = create :tomato
    end

    context "with no seeds" do
      it 'renders' do
        expect(helper.display_seed_availability(@member, @crop)).to eq "You don't have any seeds of this crop."
      end
    end

    context "with an unknown quantity of seeds" do
      before do
        create :seed, crop: @crop, quantity: nil, owner: @member
      end

      it 'renders' do
        expect(
          helper.display_seed_availability(@member, @crop)
        ).to eq "You have an unknown quantity of seeds of this crop."
      end
    end

    context "with an quantity of seeds" do
      before do
        a_different_crop = create :apple

        create :seed, crop: @crop, quantity: 20, owner: @member
        create :seed, crop: @crop, quantity: 13, owner: @member

        create :seed, crop: a_different_crop, quantity: 3, owner: @member
      end

      it 'renders' do
        expect(helper.display_seed_availability(@member, @crop)).to eq "You have 33 seeds of this crop."
      end
    end
  end
end
