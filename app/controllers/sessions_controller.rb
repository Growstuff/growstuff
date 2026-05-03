# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  respond_to :html, :json

  def create
    super do |_resource|
      flash[:alert] = t('messages.crops_waiting') if Crop.pending_approval.present? && current_member.role?(:crop_wrangler)
    end
  end
end
