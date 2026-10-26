# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "Growstuff <#{ENV.fetch('GROWSTUFF_EMAIL', nil)}>"
  layout 'mailer'
end
