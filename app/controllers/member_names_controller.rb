# frozen_string_literal: true

# Confirming the login name someone was given when they joined through another
# site: they keep it, or choose their own, from the to-do list on the home page.
class MemberNamesController < ApplicationController
  before_action :authenticate_member!

  def update
    if current_member.update(login_name: params.require(:member)[:login_name])
      current_member.confirm_username!
      redirect_to root_path, notice: t('.saved')
    else
      redirect_to root_path, alert: current_member.errors.full_messages.to_sentence
    end
  end
end
