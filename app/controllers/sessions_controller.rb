class SessionsController < Devise::SessionsController
  respond_to :json

  def create
    super do |_resource|
      flash[:alert] = "There are crops waiting to be wrangled." if Crop.pending_approval.present? && current_member.role?(:crop_wrangler)
      flash[:info] = "Someone has requested a seed trade." if Trade.where(owner: current_member)
    end
  end
end
