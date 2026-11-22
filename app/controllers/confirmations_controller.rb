# frozen_string_literal: true

class ConfirmationsController < Devise::ConfirmationsController
  # The browser that signed up carries this in its session. Following the
  # confirmation link there signs them in, as they have just given their
  # password; anyone else with the link still has to sign in.
  SIGNED_UP_KEY = 'signed_up_member'
  SIGN_IN_WINDOW = 2.days

  def show
    super do |member|
      sign_in(resource_name, member) if member.errors.empty? && signed_up_in_this_browser?(member)
    end
  end

  protected

  # Someone who has just confirmed in another browser isn't signed in, so send
  # them to sign in with their login name already filled in.
  def after_confirmation_path_for(resource_name, resource)
    return super if signed_in?(resource_name)

    new_session_path(resource_name, login: resource.login_name)
  end

  private

  def signed_up_in_this_browser?(member)
    signed_up = session.delete(SIGNED_UP_KEY)
    signed_up.present? && signed_up['id'] == member.id && signed_up['at'].to_i > SIGN_IN_WINDOW.ago.to_i
  end
end
