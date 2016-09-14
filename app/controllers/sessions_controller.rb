class SessionsController < Devise::SessionsController
  respond_to :json

  def create
    super do |resource|
      if Crop.pending_approval.present? && current_member.has_role?(:crop_wrangler)
        flash[:alert] = "There are crops waiting to be wrangled."
      end
    end
  end
end
