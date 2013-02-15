class Ability
  include CanCan::Ability

  def initialize(member)
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities

    # everyone can do these things, even non-logged in
    can :read, :all
    cannot :read, Notification

    if member
      # managing your own user settings
      can :update, Member, :id => member.id

      # can read/delete notifications that were sent to them
      can :read, Notification, :to_id => member.id
      can :destroy, Notification, :to_id => member.id
      # note we don't support create/update for notifications

      # for now, anyone can create/edit/destroy crops
      # (later, we probably want to limit this to a role)
      can :create, Crop
      can :update, Crop
      can :destroy, Crop
      can :create, ScientificName
      can :update, ScientificName
      can :destroy, ScientificName

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
