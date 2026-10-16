# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  respond_to :html, :json

  def create
    super do |_resource|
      flash[:notice] = t('devise.sessions.signed_in') if request.format.json?
      flash[:alert] = t('messages.crops_waiting') if Crop.pending_approval.present? && current_member.role?(:crop_wrangler)
    end
  end

  private

  # The sign in dialog reloads the page it was opened over, so a success needs
  # no body. A failure is Devise's own 401 with an `error` message.
  def respond_with(*args, &)
    return head :no_content if request.format.json? && member_signed_in?

    super
  end
end
