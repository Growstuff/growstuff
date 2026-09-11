# frozen_string_literal: true

class PushNotificationService
  def initialize(member, message)
    @member = member
    @message = message
  end

  def send
    @member.push_subscriptions.each do |subscription|
      begin
        WebPush.payload_send(
          message: JSON.generate(title: 'Growstuff', body: @message),
          endpoint: subscription.endpoint,
          p256dh: subscription.p256dh,
          auth: subscription.auth,
          vapid: {
            subject: "mailto:#{ENV.fetch('GROWSTUFF_EMAIL', 'noreply@growstuff.org')}",
            public_key: ENV['GROWSTUFF_VAPID_PUBLIC_KEY'],
            private_key: ENV['GROWSTUFF_VAPID_PRIVATE_KEY']
          }
        )
      rescue WebPush::InvalidSubscription => e
        # A subscription can become invalid if the user revokes the permission.
        # In this case, we should delete the subscription.
        subscription.destroy
        Rails.logger.info "Subscription deleted because it was invalid: #{e.message}"
      end
    end
  end
end
