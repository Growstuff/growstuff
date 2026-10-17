# frozen_string_literal: true

# An ability that answers each permission question once. The cards ask the same
# few things (can I edit this planting, can I add a photo) of every planting on
# the page, and CanCan works each answer out from its rules every time.
class CachedAbility
  def initialize(ability)
    @ability = ability
    @answers = {}
  end

  def can?(*args)
    @answers.fetch(args) { @answers[args] = @ability.can?(*args) }
  end
end
