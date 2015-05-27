class Ability
  include CanCan::Ability

  def initialize(member)
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities

    # everyone can do these things, even non-logged in
    can :read, :all
    can :view_follows, Member
    can :view_followers, Member

    # except these, which don't make sense if you're not logged in
    cannot :read, Notification
    cannot :read, Authentication
    cannot :read, Order
    cannot :read, OrderItem

    # and nobody should be able to view this except admins
    cannot :read, Role
    cannot :read, Product
    cannot :read, Account
    cannot :read, AccountType

    # nobody should be able to view unapproved crops unless they
    # are wranglers or admins 
    cannot :read, Crop
    can :read, Crop, :approval_status => "approved"
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

    if member
      # members can see even rejected or pending crops if they requested it
      can :read, Crop, :requester_id => member.id

      # managing your own user settings
      can :update, Member, :id => member.id

      # can read/delete notifications that were sent to them
      can :read, Notification, :recipient_id => member.id
      can :destroy, Notification, :recipient_id => member.id
      can :reply, Notification, :recipient_id => member.id
      # can send a private message to anyone but themselves
      # note: sadly, we can't test for this from the view, but it works
      # for the model/controller
      can :create, Notification do |n|
        n.recipient_id != member.id
      end
      # note we don't support update for notifications

      # only crop wranglers can create/edit/destroy crops
      if member.has_role? :crop_wrangler
        can :wrangle, Crop
        can :manage, Crop
        can :manage, ScientificName
        can :manage, AlternateName
      end

      # any member can create a crop provisionally
      can :create, Crop

      # can create & destroy their own authentications against other sites.
      can :create, Authentication
      can :destroy, Authentication, :member_id => member.id

      # anyone can create a post, or comment on a post,
      # but only the author can edit/destroy it.
      can :create,  Post
      can :update,  Post, :author_id => member.id
      can :destroy, Post, :author_id => member.id
      can :create,  Comment
      can :update,  Comment, :author_id => member.id
      can :destroy, Comment, :author_id => member.id

      # same deal for gardens and plantings
      can :create,  Garden
      can :update,  Garden, :owner_id => member.id
      can :destroy, Garden, :owner_id => member.id

      can :create,  Planting
      can :update,  Planting, :garden => { :owner_id => member.id }
      can :destroy, Planting, :garden => { :owner_id => member.id }

      can :create,  Harvest
      can :update,  Harvest, :owner_id => member.id
      can :destroy, Harvest, :owner_id => member.id

      can :create, Photo
      can :update, Photo, :owner_id => member.id
      can :destroy, Photo, :owner_id => member.id

      can :create, Seed
      can :update, Seed, :owner_id => member.id
      can :destroy, Seed, :owner_id => member.id

      # orders/shop/etc
      can :create,   Order
      can :read,     Order, :member_id => member.id
      can :complete, Order, :member_id => member.id, :completed_at => nil
      can :checkout, Order, :member_id => member.id, :completed_at => nil
      can :cancel,   Order, :member_id => member.id, :completed_at => nil
      can :destroy,  Order, :member_id => member.id, :completed_at => nil

      can :create,  OrderItem
      # for now, let's not let people mess with individual order items
      cannot :read,    OrderItem, :order => { :member_id => member.id }
      cannot :update,  OrderItem, :order => { :member_id => member.id, :completed_at => nil }
      cannot :destroy, OrderItem, :order => { :member_id => member.id, :completed_at => nil }

      # following/unfollowing permissions
      can :create, Follow
      cannot :create, Follow, :followed_id => member.id # can't follow yourself

      can :destroy, Follow
      cannot :destroy, Follow, :followed_id => member.id # can't unfollow yourself

      if member.has_role? :admin

        can :read, :all
        can :manage, :all

        # can't change order history, because it's *history*
        cannot :create, Order
        cannot :complete, Order
        cannot :destroy, Order
        cannot :manage, OrderItem

        # can't delete plant parts if they have harvests associated with them
        cannot :destroy, PlantPart
        can :destroy, PlantPart do |pp|
          pp.harvests.empty?
        end

      end

    end
  end
end
