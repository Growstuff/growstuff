class Ability
  include CanCan::Ability

  def initialize(member)
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities

    # everyone can do these things, even non-logged in
    can :read, :all

    if member
      # managing your own user settings
      can :update, Member, :id => member.id

      # for now, anyone can create/edit/destroy crops
      # (later, we probably want to limit this to a role)
      can :create, Crop
      can :update, Crop
      can :destroy, Crop
      can :create, ScientificName
      can :update, ScientificName
      can :destroy, ScientificName

      # anyone can create a post, but only the author can edit/destroy
      # it.
      can :create, Post
      can :update, Post, :author_id => member.id
      can :destroy, Post, :author_id => member.id

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
