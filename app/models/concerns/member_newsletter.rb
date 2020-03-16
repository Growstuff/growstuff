# frozen_string_literal: true

module MemberNewsletter
  extend ActiveSupport::Concern

  included do
    after_save :update_newsletter_subscription
    before_destroy :newsletter_unsubscribe

    scope :wants_newsletter, -> { where(newsletter: true) }

    def update_newsletter_subscription
      return unless will_save_change_to_attribute?(:confirmed) || will_save_change_to_attribute?(:newsletter)

      if newsletter
        newsletter_subscribe if confirmed_just_now? || requested_newsletter_just_now?
      elsif confirmed_at
        newsletter_unsubscribe
      end
    end

    def confirmed_just_now?
      will_save_change_to_attribute?(:confirmed_at)
    end

    def requested_newsletter_just_now?
      confirmed_at && will_save_change_to_attribute?(:newsletter)
    end

    def newsletter_subscribe(gibbon = Gibbon::API.new, testing = false)
      return true if Rails.env.test? && !testing

      gibbon.lists.subscribe(
        id:           Rails.application.config.newsletter_list_id,
        email:        { email: email },
        merge_vars:   { login_name: login_name },
        double_optin: false # they already confirmed their email with us
      )
    end

    def newsletter_unsubscribe(gibbon = Gibbon::API.new, testing = false)
      return true if Rails.env.test? && !testing

      gibbon.lists.unsubscribe(id:    Rails.application.config.newsletter_list_id,
                               email: { email: email })
    end
  end
end
