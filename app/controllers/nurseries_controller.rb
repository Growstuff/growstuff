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

  # Just the nursery on the gardens page, for refreshing it in place after
  # something is saved in a dialog.
  def panel
    render partial: 'gardens/nursery_panel', locals: { nursery: current_member.nursery }
  end

  def create
    nursery = if params[:garden_slug].present?
                current_member.gardens.find_by!(slug: params[:garden_slug]).tap(&:make_nursery!)
              else
                current_member.nursery!
              end
    redirect_to nursery, notice: t('gardens.nursery_made')
  end
end
