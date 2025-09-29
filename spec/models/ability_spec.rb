# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

describe Ability do
  let(:member)  { FactoryBot.create(:member) }
  let(:ability) { described_class.new(member) }

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
                                                      sender:    member))
    end

    it "member can send messages to someone else" do
      ability.should be_able_to(:create,
                                FactoryBot.create(:notification,
                                                  recipient: FactoryBot.create(:member),
                                                  sender:    member))
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

      before do
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

  context 'plantings' do
    let(:approved_crop) { FactoryBot.create(:crop, approval_status: 'approved') }
    let(:unapproved_crop) { FactoryBot.create(:crop, approval_status: 'unapproved') }
    let(:planting) { FactoryBot.create(:planting, garden: FactoryBot.create(:garden, owner: member), crop: approved_crop) }
    let(:other_planting) { FactoryBot.create(:planting, crop: approved_crop) }
    let(:planting_with_unapproved_crop) { FactoryBot.create(:planting, garden: FactoryBot.create(:garden, owner: member), crop: unapproved_crop) }

    it 'can create a planting' do
      ability.should be_able_to(:create, Planting)
    end

    it 'can manage their own planting with an approved crop' do
      ability.should be_able_to(:update, planting)
      ability.should be_able_to(:destroy, planting)
    end

    it "can't manage their own planting with an unapproved crop" do
      ability.should_not be_able_to(:update, planting_with_unapproved_crop)
      ability.should_not be_able_to(:destroy, planting_with_unapproved_crop)
    end

    it "can't manage another member's planting" do
      ability.should_not be_able_to(:update, other_planting)
      ability.should_not be_able_to(:destroy, other_planting)
    end

    it 'can transplant their own planting' do
      ability.should be_able_to(:transplant, planting)
    end

    context 'garden collaborator' do
      let(:garden) { FactoryBot.create(:garden) }
      let(:planting_in_garden) { FactoryBot.create(:planting, garden:, crop: approved_crop) }

      before do
        garden.garden_collaborators.create(member:)
      end

      it 'can manage plantings in a garden they collaborate on' do
        ability.should be_able_to(:update, planting_in_garden)
        ability.should be_able_to(:destroy, planting_in_garden)
      end

      it 'can transplant a planting in a garden they collaborate on' do
        ability.should be_able_to(:transplant, planting_in_garden)
      end
    end
  end

  context 'harvests' do
    let(:harvest) { FactoryBot.create(:harvest, owner: member) }
    let(:other_harvest) { FactoryBot.create(:harvest) }

    it 'can create a harvest' do
      ability.should be_able_to(:create, Harvest)
    end

    it 'can manage their own harvest' do
      ability.should be_able_to(:update, harvest)
      ability.should be_able_to(:destroy, harvest)
    end

    it "can't manage another member's harvest" do
      ability.should_not be_able_to(:update, other_harvest)
      ability.should_not be_able_to(:destroy, other_harvest)
    end

    context 'garden collaborator' do
      let(:garden) { FactoryBot.create(:garden) }
      let(:planting_in_garden) { FactoryBot.create(:planting, garden:) }
      let(:harvest_in_garden) { FactoryBot.create(:harvest, planting: planting_in_garden) }

      before do
        garden.garden_collaborators.create(member:)
      end

      it 'can manage harvests in a garden they collaborate on' do
        ability.should be_able_to(:update, harvest_in_garden)
        ability.should be_able_to(:destroy, harvest_in_garden)
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
        @harvest = FactoryBot.create(:harvest, plant_part:)
        ability.should_not be_able_to(:destroy, plant_part)
      end
    end
  end

  context 'members' do
    context 'ordinary member' do
      it "can't manage members" do
        ability.should_not be_able_to(:destroy, Member)
      end
    end

    context 'admin' do
      let(:role) { FactoryBot.create(:admin) }

      before do
        member.roles << role
      end

      it "can manage members" do
        ability.should be_able_to(:destroy, FactoryBot.create(:member))
      end
      it "cannot delete themselves" do
        ability.should_not be_able_to(:destroy, member)
      end
    end
  end

  context 'activities' do
    let(:activity) { FactoryBot.create(:activity, owner: member) }
    let(:other_activity) { FactoryBot.create(:activity) }

    it 'can create an activity' do
      ability.should be_able_to(:create, Activity)
    end

    it 'can manage their own activity' do
      ability.should be_able_to(:update, activity)
      ability.should be_able_to(:destroy, activity)
    end

    it "can't manage another member's activity" do
      ability.should_not be_able_to(:update, other_activity)
      ability.should_not be_able_to(:destroy, other_activity)
    end

    context 'garden collaborator' do
      let(:garden) { FactoryBot.create(:garden) }
      let(:activity_in_garden) { FactoryBot.create(:activity, garden:) }

      before do
        garden.garden_collaborators.create(member:)
      end

      it 'can manage activities in a garden they collaborate on' do
        ability.should be_able_to(:update, activity_in_garden)
        ability.should be_able_to(:destroy, activity_in_garden)
      end
    end
  end

  context 'seeds' do
    let(:seed) { FactoryBot.create(:seed, owner: member) }
    let(:other_seed) { FactoryBot.create(:seed) }

    it 'can create a seed' do
      ability.should be_able_to(:create, Seed)
    end

    it 'can manage their own seed' do
      ability.should be_able_to(:update, seed)
      ability.should be_able_to(:destroy, seed)
    end

    it "can't manage another member's seed" do
      ability.should_not be_able_to(:update, other_seed)
      ability.should_not be_able_to(:destroy, other_seed)
    end
  end

  context 'comments' do
    let(:comment) { FactoryBot.create(:comment, author: member) }
    let(:other_comment) { FactoryBot.create(:comment) }

    it 'can create a comment' do
      ability.should be_able_to(:create, Comment)
    end

    it 'can manage their own comment' do
      ability.should be_able_to(:update, comment)
      ability.should be_able_to(:destroy, comment)
    end

    it "can't manage another member's comment" do
      ability.should_not be_able_to(:update, other_comment)
      ability.should_not be_able_to(:destroy, other_comment)
    end
  end

  context 'photos' do
    let(:photo) { FactoryBot.create(:photo, owner: member) }
    let(:other_photo) { FactoryBot.create(:photo) }

    it 'can create a photo' do
      ability.should be_able_to(:create, Photo)
    end

    it 'can manage their own photo' do
      ability.should be_able_to(:update, photo)
      ability.should be_able_to(:destroy, photo)
    end

    it "can't manage another member's photo" do
      ability.should_not be_able_to(:update, other_photo)
      ability.should_not be_able_to(:destroy, other_photo)
    end
  end

  context 'likes' do
    let(:like) { FactoryBot.create(:like, member:) }
    let(:other_like) { FactoryBot.create(:like) }

    it 'can create a like' do
      ability.should be_able_to(:create, Like)
    end

    it 'can destroy their own like' do
      ability.should be_able_to(:destroy, like)
    end

    it "can't destroy another member's like" do
      ability.should_not be_able_to(:destroy, other_like)
    end
  end
end
