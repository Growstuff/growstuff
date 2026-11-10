# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

describe Ability do
  let(:member)  { create(:member) }
  let(:ability) { described_class.new(member) }

  describe "notifications" do
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

  describe 'scientific names and alternate names' do
    let(:approved_crop) { create(:crop, approval_status: 'approved') }
    let(:pending_crop) { create(:crop, approval_status: 'pending') }
    let(:scientific_name) { create(:scientific_name, crop: approved_crop) }
    let(:unapproved_scientific_name) { create(:scientific_name, crop: pending_crop) }
    let(:alternate_name) { create(:alternate_name, crop: approved_crop) }
    let(:unapproved_alternate_name) { create(:alternate_name, crop: pending_crop) }

    it 'can read scientific names and alternate names of approved crops' do
      expect(ability).to be_able_to(:read, scientific_name)
      expect(ability).to be_able_to(:read, alternate_name)
    end

    it 'cannot read scientific names and alternate names of unapproved crops' do
      expect(ability).not_to be_able_to(:read, unapproved_scientific_name)
      expect(ability).not_to be_able_to(:read, unapproved_alternate_name)
    end
  end

  describe "crop wrangling" do
    let(:crop) { create(:crop) }

    context "when the member is a standard member" do
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

    context "when the member is a crop wrangler" do
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

  describe 'plantings' do
    let(:approved_crop) { create(:crop, approval_status: 'approved') }
    let(:unapproved_crop) { create(:crop, approval_status: 'unapproved') }
    let(:garden) { create(:garden, owner: member) }
    let(:planting) { create(:planting, garden: garden, crop: approved_crop, owner: member) }
    let(:other_planting) { create(:planting, crop: approved_crop) }
    let(:planting_with_unapproved_crop) { create(:planting, garden: garden, crop: unapproved_crop, owner: member) }

    it 'can create a planting' do
      expect(ability).to be_able_to(:create, Planting)
    end

    it 'can manage their own planting with an approved crop' do
      expect(ability).to be_able_to(:update, planting)
      expect(ability).to be_able_to(:destroy, planting)
    end

    xit "can't manage their own planting with an unapproved crop" do
      expect(ability).not_to be_able_to(:update, planting_with_unapproved_crop)
      expect(ability).not_to be_able_to(:destroy, planting_with_unapproved_crop)
    end

    it "can't manage another member's planting" do
      expect(ability).not_to be_able_to(:update, other_planting)
      expect(ability).not_to be_able_to(:destroy, other_planting)
    end

    it 'can transplant their own planting' do
      expect(ability).to be_able_to(:transplant, planting)
    end

    context 'when the member is a garden collaborator' do
      let(:garden) { create(:garden) }
      let(:planting_in_garden) { create(:planting, garden:, crop: approved_crop, owner: garden.owner) }

      before do
        garden.garden_collaborators.create(member:)
      end

      it 'can manage plantings in a garden they collaborate on' do
        expect(ability).to be_able_to(:update, planting_in_garden)
        expect(ability).to be_able_to(:destroy, planting_in_garden)
      end

      it 'can transplant a planting in a garden they collaborate on' do
        expect(ability).to be_able_to(:transplant, planting_in_garden)
      end
    end
  end

  describe 'harvests' do
    let(:harvest) { create(:harvest, owner: member) }
    let(:other_harvest) { create(:harvest) }

    it 'can create a harvest' do
      expect(ability).to be_able_to(:create, Harvest)
    end

    it 'can manage their own harvest' do
      expect(ability).to be_able_to(:update, harvest)
      expect(ability).to be_able_to(:destroy, harvest)
    end

    it "can't manage another member's harvest" do
      expect(ability).not_to be_able_to(:update, other_harvest)
      expect(ability).not_to be_able_to(:destroy, other_harvest)
    end

    context 'when the member is a garden collaborator' do
      let(:garden) { create(:garden) }
      let(:planting_in_garden) { create(:planting, garden:, owner: garden.owner) }
      let(:harvest_in_garden) { create(:harvest, planting: planting_in_garden, owner: planting_in_garden.owner) }

      before do
        garden.garden_collaborators.create(member:)
      end

      it 'can manage harvests in a garden they collaborate on' do
        expect(ability).to be_able_to(:update, harvest_in_garden)
        expect(ability).to be_able_to(:destroy, harvest_in_garden)
      end
    end
  end

  describe 'plant parts' do
    let(:plant_part) { create(:plant_part) }

    context 'when the member is an ordinary member' do
      it "can read plant parts" do
        expect(ability).to be_able_to(:read, plant_part)
      end

      it "can't manage plant parts" do
        expect(ability).not_to be_able_to(:create, PlantPart)
        expect(ability).not_to be_able_to(:update, plant_part)
        expect(ability).not_to be_able_to(:destroy, plant_part)
      end
    end

    context 'when the member is an admin' do
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

  describe 'members' do
    context 'when the member is an ordinary member' do
      it "can't manage members" do
        expect(ability).not_to be_able_to(:destroy, Member)
      end
    end

    context 'when the member is an admin' do
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

  describe 'jobs' do
    let(:job) { create(:job, owner: member) }
    let(:other_job) { create(:job) }

    it 'can create a job' do
      expect(ability).to be_able_to(:create, Job)
    end

    it 'can manage their own job' do
      expect(ability).to be_able_to(:update, job)
      expect(ability).to be_able_to(:destroy, job)
    end

    it "can't manage another member's job" do
      expect(ability).not_to be_able_to(:update, other_job)
      expect(ability).not_to be_able_to(:destroy, other_job)
    end

    context 'when an admin' do
      let(:role) { create(:admin) }

      before { member.roles << role }

      it "can't update another member's job" do
        expect(ability).not_to be_able_to(:update, other_job)
      end

      it "can't destroy another member's job" do
        expect(ability).not_to be_able_to(:destroy, other_job)
      end

      it 'can update their own job' do
        expect(ability).to be_able_to(:update, job)
      end
    end

    context 'when the member is a garden collaborator' do
      let(:garden) { create(:garden) }
      let(:job_in_garden) { create(:job, garden:) }

      before do
        garden.garden_collaborators.create(member:)
      end

      it 'can manage jobs in a garden they collaborate on' do
        expect(ability).to be_able_to(:update, job_in_garden)
        expect(ability).to be_able_to(:destroy, job_in_garden)
      end
    end

    context 'when the member is the garden owner' do
      let(:garden) { create(:garden, owner: member) }
      let(:collaborator) { create(:member) }
      let(:job_in_garden) { create(:job, owner: collaborator, garden:) }

      it 'can update jobs in their garden created by collaborators' do
        expect(ability).to be_able_to(:update, job_in_garden)
      end

      it 'can destroy jobs in their garden created by collaborators' do
        expect(ability).to be_able_to(:destroy, job_in_garden)
      end
    end
  end

  describe 'seeds' do
    let(:seed) { create(:seed, owner: member) }
    let(:other_seed) { create(:seed) }

    it 'can create a seed' do
      expect(ability).to be_able_to(:create, Seed)
    end

    it 'can manage their own seed' do
      expect(ability).to be_able_to(:update, seed)
      expect(ability).to be_able_to(:destroy, seed)
    end

    it "can't manage another member's seed" do
      expect(ability).not_to be_able_to(:update, other_seed)
      expect(ability).not_to be_able_to(:destroy, other_seed)
    end
  end

  describe 'comments' do
    let(:comment) { create(:comment, author: member) }
    let(:other_comment) { create(:comment) }

    it 'can create a comment' do
      expect(ability).to be_able_to(:create, Comment)
    end

    it 'can manage their own comment' do
      expect(ability).to be_able_to(:update, comment)
      expect(ability).to be_able_to(:destroy, comment)
    end

    it "can't manage another member's comment" do
      expect(ability).not_to be_able_to(:update, other_comment)
      expect(ability).not_to be_able_to(:destroy, other_comment)
    end
  end

  describe 'photos' do
    let(:photo) { create(:photo, owner: member) }
    let(:other_photo) { create(:photo) }

    it 'can create a photo' do
      expect(ability).to be_able_to(:create, Photo)
    end

    context 'when a crop wrangler' do
      let(:member) { create(:crop_wrangling_member) }

      it 'can delete a photo from Flickr that cropbot owns' do
        expect(ability).to be_able_to(:destroy, create(:photo, author_name: 'Pat Photo'))
      end

      it 'can refresh any photo' do
        expect(ability).to be_able_to(:refresh, other_photo)
      end

      it "cannot delete another member's own photo" do
        expect(ability).not_to be_able_to(:destroy, other_photo)
      end
    end

    it 'can refresh their own photo' do
      expect(ability).to be_able_to(:refresh, photo)
    end

    it "cannot refresh another member's photo" do
      expect(ability).not_to be_able_to(:refresh, other_photo)
    end

    it 'can manage their own photo' do
      expect(ability).to be_able_to(:update, photo)
      expect(ability).to be_able_to(:destroy, photo)
    end

    it "can't manage another member's photo" do
      expect(ability).not_to be_able_to(:update, other_photo)
      expect(ability).not_to be_able_to(:destroy, other_photo)
    end
  end

  describe 'likes' do
    let(:like) { create(:like, member:) }
    let(:other_like) { create(:like) }

    it 'can create a like' do
      expect(ability).to be_able_to(:create, Like)
    end

    it 'can destroy their own like' do
      expect(ability).to be_able_to(:destroy, like)
    end

    it "can't destroy another member's like" do
      expect(ability).not_to be_able_to(:destroy, other_like)
    end
  end
end
