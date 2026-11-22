# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  respond_to :html, :json

  # Confirming an account lands here with the name they signed up with, so
  # all that is left to type is the password.
  def new
    super { |resource| resource.login = params[:login] if params[:login].present? }
  end

  def create
    super do |_resource|
      flash[:notice] = t('devise.sessions.signed_in') if request.format.json?
      flash[:alert] = t('messages.crops_waiting') if Crop.pending_approval.present? && current_member.role?(:crop_wrangler)
      flash[:alert] = location_prompt if current_member.location_unplaced? && request.format.html?
    end
  end

  private

  def location_prompt
    t('messages.location_unplaced_html', location: ERB::Util.h(current_member.location), link: edit_member_registration_path)
  end

  # The sign in dialog reloads the page it was opened over, so a success needs
  # no body. A failure is Devise's own 401 with an `error` message.
  def respond_with(*args, &)
    return head :no_content if request.format.json? && member_signed_in?

    super
  end
end
