# frozen_string_literal: true

# The home page's to-do list asking for an email: adding one, saying no thanks,
# or asking for the confirmation link again.
class MemberEmailsController < ApplicationController
  RESEND_AFTER = 1.minute

  before_action :authenticate_member!

  # The address waits as unconfirmed until its link is followed.
  def update
    email = params.require(:member)[:email]
    return redirect_to(root_path, alert: t('.blank')) if email.blank?

    if current_member.update(email:)
      redirect_to root_path, notice: t('.sent')
    else
      redirect_to root_path, alert: current_member.errors.full_messages.to_sentence
    end
  end

  def decline
    current_member.decline_email!
    respond_to do |format|
      format.html { redirect_to root_path, notice: t('.declined') }
      format.json { head :no_content }
    end
  end

  def resend
    if current_member.confirmation_sent_at.nil? || current_member.confirmation_sent_at < RESEND_AFTER.ago
      current_member.send_confirmation_instructions
      redirect_to root_path, notice: t('.sent')
    else
      redirect_to root_path, alert: t('.wait')
    end
  end
end
