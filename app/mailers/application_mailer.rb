# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "Growstuff <#{Rails.configuration.x.email[:from]}>"
  layout 'mailer'
end
