# frozen_string_literal: true

# A member's nursery, where they raise seedlings before planting them out. One
# per member. A member without one is asked whether they want one: an existing
# garden, a new one, or none.
class NurseriesController < ApplicationController
  before_action :authenticate_member!

  def show
    return redirect_to current_member.nursery if current_member.nursery

    @candidates = current_member.gardens.active.not_nurseries.order_by_name
  end

  def create
    garden = current_member.gardens.find_by!(slug: params[:garden_slug]) if params[:garden_slug].present?
    garden ? garden.make_nursery! : garden = current_member.nursery!
    redirect_to garden, notice: t('gardens.nursery_made')
  end
end
