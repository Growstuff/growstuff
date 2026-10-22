# frozen_string_literal: true

class DeviseMailer < Devise::Mailer
  protected

  def subject_for(key)
    options = { site_name: ENV.fetch('GROWSTUFF_SITE_NAME', 'Growstuff') }
    I18n.t(:"#{devise_mapping.name}_subject", scope: [:devise, :mailer, key], default: [:subject, key.to_s.humanize], **options)
  end
end
