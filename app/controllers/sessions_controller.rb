class SessionsController < Devise::SessionsController
  respond_to :json

  def create
    super do |_resource|
      if Crop.pending_approval.present? && current_member.role?(:crop_wrangler)
        flash[:alert] = "There are crops waiting to be wrangled."
      end
      if Trade.where(owner: current_member)
        flash[:info] = "Someone has requested a seed trade."
      end
    end
  end
end
