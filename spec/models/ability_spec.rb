require 'rails_helper'
require 'cancan/matchers'

describe Ability do
  let(:member) { FactoryBot.create(:member) }
  let(:ability) { Ability.new(member) }

  context "notifications" do
    it 'member can view their own notifications' do
      notification = FactoryBot.create(:notification, recipient: member)
      ability.should be_able_to(:read, notification)
    end

    it "member can't view someone else's notifications" do
      notification = FactoryBot.create(:notification,
        recipient: FactoryBot.create(:member))
      ability.should_not be_able_to(:read, notification)
    end
    it "member can't send messages to themself" do
      ability.should_not be_able_to(:create,
        FactoryBot.create(:notification,
          recipient: member,
          sender: member))
    end
    it "member can send messages to someone else" do
      ability.should be_able_to(:create,
        FactoryBot.create(:notification,
          recipient: FactoryBot.create(:member),
          sender: member))
    end
  end

  context "crop wrangling" do
    let(:crop) { FactoryBot.create(:crop) }

    context "standard member" do
      it "can't manage crops" do
        ability.should_not be_able_to(:update, crop)
        ability.should_not be_able_to(:destroy, crop)
      end

      it "can request crops" do
        ability.should be_able_to(:create, Crop)
      end

      it "can read crops" do
        ability.should be_able_to(:read, crop)
      end
    end

    context "crop wrangler" do
      let(:role) { FactoryBot.create(:crop_wrangler) }

      before(:each) do
        member.roles << role
      end

      it "has crop_wrangler role" do
        member.role?(:crop_wrangler).should be true
      end

      it "can create crops" do
        ability.should be_able_to(:create, Crop)
      end
      it "can update crops" do
        ability.should be_able_to(:update, crop)
      end
      it "can destroy crops" do
        ability.should be_able_to(:destroy, crop)
      end
    end
  end

  context 'plant parts' do
    let(:plant_part) { FactoryBot.create(:plant_part) }

    context 'ordinary member' do
      it "can read plant parts" do
        ability.should be_able_to(:read, plant_part)
      end
      it "can't manage plant parts" do
        ability.should_not be_able_to(:create, PlantPart)
        ability.should_not be_able_to(:update, plant_part)
        ability.should_not be_able_to(:destroy, plant_part)
      end
    end

    context 'admin' do
      let(:role) { FactoryBot.create(:admin) }

      before do
        member.roles << role
      end

      it "can read plant_part details" do
        ability.should be_able_to(:read, plant_part)
      end
      it "can manage plant_part details" do
        ability.should be_able_to(:create, PlantPart)
        ability.should be_able_to(:update, plant_part)
      end

      it "can delete an unused plant part" do
        ability.should be_able_to(:destroy, plant_part)
      end

      it "can't delete a plant part that has harvests" do
        @harvest = FactoryBot.create(:harvest, plant_part: plant_part)
        ability.should_not be_able_to(:destroy, plant_part)
      end
    end
  end
end
