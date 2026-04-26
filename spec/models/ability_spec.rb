# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

describe Ability do
  let(:member)  { create(:member) }
  let(:ability) { described_class.new(member) }

  context "notifications" do
    it 'member can view their own notifications' do
      notification = create(:notification, recipient: member)
      expect(ability).to be_able_to(:read, notification)
    end

    it "member can't view someone else's notifications" do
      notification = create(:notification,
                            recipient: create(:member))
      expect(ability).not_to be_able_to(:read, notification)
    end

    it "member can't send messages to themself" do
      expect(ability).not_to be_able_to(:create,
                                    create(:notification,
                                           recipient: member,
                                           sender:    member))
    end

    it "member can send messages to someone else" do
      expect(ability).to be_able_to(:create,
                                create(:notification,
                                       recipient: create(:member),
                                       sender:    member))
    end
  end

  context "crop wrangling" do
    let(:crop) { create(:crop) }

    context "standard member" do
      it "can't manage crops" do
        expect(ability).not_to be_able_to(:update, crop)
        expect(ability).not_to be_able_to(:destroy, crop)
      end

      it "can request crops" do
        expect(ability).to be_able_to(:create, Crop)
      end

      it "can read crops" do
        expect(ability).to be_able_to(:read, crop)
      end
    end

    context "crop wrangler" do
      let(:role) { create(:crop_wrangler) }

      before do
        member.roles << role
      end

      it "has crop_wrangler role" do
        expect(member.role?(:crop_wrangler)).to be true
      end

      it "can create crops" do
        expect(ability).to be_able_to(:create, Crop)
      end

      it "can update crops" do
        expect(ability).to be_able_to(:update, crop)
      end

      it "can destroy crops" do
        expect(ability).to be_able_to(:destroy, crop)
      end
    end
  end

  context 'plant parts' do
    let(:plant_part) { create(:plant_part) }

    context 'ordinary member' do
      it "can read plant parts" do
        expect(ability).to be_able_to(:read, plant_part)
      end

      it "can't manage plant parts" do
        expect(ability).not_to be_able_to(:create, PlantPart)
        expect(ability).not_to be_able_to(:update, plant_part)
        expect(ability).not_to be_able_to(:destroy, plant_part)
      end
    end

    context 'admin' do
      let(:role) { create(:admin) }

      before do
        member.roles << role
      end

      it "can read plant_part details" do
        expect(ability).to be_able_to(:read, plant_part)
      end

      it "can manage plant_part details" do
        expect(ability).to be_able_to(:create, PlantPart)
        expect(ability).to be_able_to(:update, plant_part)
      end

      it "can delete an unused plant part" do
        expect(ability).to be_able_to(:destroy, plant_part)
      end

      it "can't delete a plant part that has harvests" do
        @harvest = create(:harvest, plant_part:)
        expect(ability).not_to be_able_to(:destroy, plant_part)
      end
    end
  end

  context 'members' do
    context 'ordinary member' do
      it "can't manage members" do
        expect(ability).not_to be_able_to(:destroy, Member)
      end
    end

    context 'admin' do
      let(:role) { create(:admin) }

      before do
        member.roles << role
      end

      it "can manage members" do
        expect(ability).to be_able_to(:destroy, create(:member))
      end

      it "cannot delete themselves" do
        expect(ability).not_to be_able_to(:destroy, member)
      end
    end
  end
end
