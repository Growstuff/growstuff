# frozen_string_literal: true

# For controllers that work on the signed in member's own nursery: signed in,
# and with a nursery to work on.
module NurseryScoped
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_member!
    before_action :set_nursery
  end

  private

  def set_nursery
    @nursery = current_member.nursery
    redirect_to nursery_path unless @nursery
  end
end
