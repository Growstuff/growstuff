class Ability
  include CanCan::Ability

  def initialize(member)
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities

    # everyone can do these things, even non-logged in
    can :read, :all
    cannot :read, Notification

    # nobody should be able to view this except admins
    cannot :read, Role

    if member

      if member.has_role? :admin
        # admin user roles (for authorization)
        can :read, Role
        can :manage, Role

        # for now, only admins can create/edit forums
        can :manage, Forum
      end

      # managing your own user settings
      can :update, Member, :id => member.id

      # can read/delete notifications that were sent to them
      can :read, Notification, :recipient_id => member.id
      can :destroy, Notification, :recipient_id => member.id
      # note we don't support create/update for notifications

      # only crop wranglers can create/edit/destroy crops
      if member.has_role? :crop_wrangler
        can :manage, Crop
        can :manage, ScientificName
      end

      # anyone can create a post, or comment on a post,
      # but only the author can edit/destroy it.
      can :create, Post
      can :update, Post, :author_id => member.id
      can :destroy, Post, :author_id => member.id
      can :create, Comment
      can :update, Comment, :author_id => member.id
      can :destroy, Comment, :author_id => member.id

      # same deal for gardens and plantings
      can :create, Garden
      can :update, Garden, :owner_id => member.id
      can :destroy, Garden, :owner_id => member.id

      can :create, Planting
      can :update, Planting, :garden => { :owner_id => member.id }
      can :destroy, Planting, :garden => { :owner_id => member.id }
    end
  end
end
