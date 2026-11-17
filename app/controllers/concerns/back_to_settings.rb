# frozen_string_literal: true

# Connecting an account starts on the settings page and ends back there. A browser doesn't
# send the tab it was on, so the way back to the settings page names the Apps tab.
module BackToSettings
  extend ActiveSupport::Concern

  private

  def apps_tab_path
    edit_member_registration_path(anchor: 'apps')
  end

  # Where OmniAuth says the member came from, or the default if it doesn't say.
  def back_to_origin(default)
    origin = request.env['omniauth.origin']
    return default if origin.blank?

    URI(origin).path == edit_member_registration_path ? apps_tab_path : origin
  rescue URI::InvalidURIError
    default
  end
end
