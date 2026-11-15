# frozen_string_literal: true

class DeviseMailer < Devise::Mailer
  layout 'mailer'

  protected

  def devise_mail(record, action, opts = {}, &block)
    I18n.with_locale(record.locale || I18n.default_locale) do
      super
    end
  end

  def subject_for(key)
    options = { site_name: ENV.fetch('GROWSTUFF_SITE_NAME', 'Growstuff') }
    I18n.t(:"#{devise_mapping.name}_subject", scope: [:devise, :mailer, key], default: [:subject, key.to_s.humanize], **options)
  end
end
