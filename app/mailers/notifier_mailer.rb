# frozen_string_literal: true

class NotifierMailer < ApplicationMailer
  default from: "Growstuff <#{ENV.fetch('GROWSTUFF_EMAIL', nil)}>"
  helper PlantingWeatherHelper

  def verifier
    unless ENV['RAILS_SECRET_TOKEN']
      raise "RAILS_SECRET_TOKEN environment variable" \
            "not set - have you created config/application.yml?"
    end

    ActiveSupport::MessageVerifier.new(ENV.fetch('RAILS_SECRET_TOKEN', nil))
  end

  def planting_reminder(member)
    I18n.with_locale(member.locale || I18n.default_locale) do
      @member = member
      @sitename = ENV.fetch('GROWSTUFF_SITE_NAME', nil)

      @late, @super_late, @harvesting, @others = @member.plantings_by_progress.values_at(:late, :super_late, :harvesting, :others)
      @outlook = PlantingReminderOutlook.new(@member)

      @subject = I18n.t('notifier_mailer.planting_reminder.subject', month_year: I18n.l(Time.zone.today, format: '%B %Y'), sitename: @sitename)

      # Encrypting
      message = { member_id: @member.id, type: :send_planting_reminder }
      @signed_message = verifier.generate(message)

      mail(to: @member.email, subject: @subject) if @member.send_planting_reminder
    end
  end

  def harvest_reminder(member)
    I18n.with_locale(member.locale || I18n.default_locale) do
      @member = member
      @plantings = @member.plantings.active.select(&:harvest_in_next_week?)
      @sitename = ENV.fetch('GROWSTUFF_SITE_NAME', nil)
      @subject = I18n.t('notifier_mailer.harvest_reminder.subject', sitename: @sitename)

      # Encrypting
      message = { member_id: @member.id, type: :send_harvest_reminder }
      @signed_message = verifier.generate(message)

      mail(to: @member.email, subject: @subject) if @member.send_harvest_reminder
    end
  end

  def new_crop_request(member, request)
    I18n.with_locale(member.locale || I18n.default_locale) do
      @member = member
      @request = request
      @subject = I18n.t('notifier_mailer.crop_request.new_subject', login_name: @request.requester.login_name, crop_name: @request.name)
      mail(to: @member.email, subject: @subject)
    end
  end

  def crop_request_approved(member, crop)
    I18n.with_locale(member.locale || I18n.default_locale) do
      @member = member
      @crop = crop
      @subject = I18n.t('notifier_mailer.crop_request.approved_subject', crop_name: crop.name.capitalize)
      mail(to: @member.email, subject: @subject)
    end
  end

  def crop_request_rejected(member, crop)
    I18n.with_locale(member.locale || I18n.default_locale) do
      @member = member
      @crop = crop
      @subject = I18n.t('notifier_mailer.crop_request.rejected_subject', crop_name: crop.name.capitalize)
      mail(to: @member.email, subject: @subject)
    end
  end
end
