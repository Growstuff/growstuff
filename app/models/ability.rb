# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(member)
    anon_abilities(member)
    member_abilities(member) if member.present?
    admin_abilities(member) if member.present? && member.role?(:admin)
  end

  def anon_abilities(_member)
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities

    # everyone can do these things, even non-logged in
    can :read, :all
    can :read, Follow
    can :followers, Follow

    # Everyone can see the charts
    can :timeline, Garden
    can :sunniness, Crop
    can :planted_from, Crop
    can :harvested_for, Crop

    # except these, which don't make sense if you're not logged in
    cannot :read, Notification
    cannot :read, Authentication

    # and nobody should be able to view this except admins
    cannot :read, Role

    # nobody should be able to view unapproved crops unless they
    # are wranglers or admins
    cannot :read, Crop
    can :read, Crop, approval_status: "approved"
    # scientific names should only be viewable if associated crop is approved
    cannot :read, ScientificName
    can :read, ScientificName do |sn|
      sn.crop.approved?
    end
    # ... same for alternate names
    cannot :read, AlternateName
    can :read, AlternateName do |an|
      an.crop.approved?
    end

    cannot :create, GardenType
    cannot :update, GardenType
    cannot :destroy, GardenType
  end

  def member_abilities(member)
    return unless member

    # members can see even rejected or pending crops if they requested it
    can :read, Crop, requester_id: member.id
    can :requested, Crop # see list of crops they've requested

    # managing your own user settings
    can :update, Member, id: member.id

    # can read/delete notifications that were sent to them
    can :read, Notification, recipient_id: member.id
    can :destroy, Notification, recipient_id: member.id
    can :reply, Notification, recipient_id: member.id
    # can send a private message to anyone but themselves
    # note: sadly, we can't test for this from the view, but it works
    # for the model/controller
    can :create, Notification do |n|
      n.recipient_id != member.id
    end
    # note we don't support update for notifications

    # only crop wranglers can create/edit/destroy crops
    if member.role? :crop_wrangler
      can :wrangle, Crop
      can :manage, Crop
      can :manage, ScientificName
      can :manage, AlternateName
      can :openfarm, Crop
    end

    # any member can create a crop provisionally
    can :create, Crop

    # can create & destroy their own authentications against other sites.
    can :create, Authentication
    can :destroy, Authentication, member_id: member.id

    # anyone can create a post, like, or comment on a post,
    # but only the author can edit/destroy it.
    can :create,  Post
    can :update,  Post, author_id: member.id
    can :destroy, Post, author_id: member.id
    can :create,  Like
    can :destroy, Like, member_id: member.id
    can :create,  Comment
    can :update,  Comment, author_id: member.id
    can :destroy, Comment, author_id: member.id

    # same deal for gardens and plantings
    can :create,  Garden
    can :update,  Garden, owner_id: member.id
    can :destroy, Garden, owner_id: member.id

    can :create,  Planting
    can :update,  Planting, garden: { owner_id: member.id }, crop: { approval_status: 'approved' }
    can :destroy, Planting, garden: { owner_id: member.id }, crop: { approval_status: 'approved' }

    can :create,  Harvest
    can :update,  Harvest, owner_id: member.id
    can :destroy, Harvest, owner_id: member.id
    can :update,  Harvest, owner_id: member.id, planting: { owner_id: member.id }
    can :destroy, Harvest, owner_id: member.id, planting: { owner_id: member.id }

    can :create, Photo
    can :update, Photo, owner_id: member.id
    can :destroy, Photo, owner_id: member.id

    can :create,  Seed
    can :update,  Seed, owner_id: member.id
    can :destroy, Seed, owner_id: member.id
    can :create,  Seed, owner_id: member.id, parent_planting: { owner_id: member.id }
    can :update,  Seed, owner_id: member.id, parent_planting: { owner_id: member.id }
    can :destroy, Seed, owner_id: member.id, parent_planting: { owner_id: member.id }

    # following/unfollowing permissions
    can :create, Follow
    cannot :create, Follow, followed_id: member.id # can't follow yourself

    can :destroy, Follow
    cannot :destroy, Follow, followed_id: member.id # can't unfollow yourself

    cannot :create, GardenType
    cannot :update, GardenType
    cannot :destroy, GardenType
  end

  def admin_abilities(member)
    return unless member.role? :admin

    can :read, :all
    can :manage, :all

    # can't delete plant parts if they have harvests associated with them
    cannot :destroy, PlantPart
    can :destroy, PlantPart do |pp|
      pp.harvests.empty?
    end
  end
end
