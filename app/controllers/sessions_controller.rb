# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  respond_to :html, :json

  def create
    super do |_resource|
      flash[:alert] = "There are crops waiting to be wrangled." if Crop.pending_approval.present? && current_member.role?(:crop_wrangler)
    end
  end
end
