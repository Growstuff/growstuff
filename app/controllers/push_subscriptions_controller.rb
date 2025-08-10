# frozen_string_literal: true

class PushSubscriptionsController < ApplicationController
  before_action :authenticate_member!

  def create
    subscription = current_member.push_subscriptions.find_or_initialize_by(endpoint: params[:subscription][:endpoint])
    subscription.update(
      p256dh: params[:subscription][:keys][:p256dh],
      auth: params[:subscription][:keys][:auth]
    )
    head :ok
  end

  def destroy
    subscription = current_member.push_subscriptions.find_by(endpoint: params[:endpoint])
    subscription&.destroy
    head :ok
  end
end
