# frozen_string_literal: true

class Admin::CropsController < ApplicationController
  before_action :authenticate_member!
  before_action :authorize_admin!

  def index
    @versions = PaperTrail::Version.where(item_type: 'Crop').order(created_at: :desc).limit(100)
    member_ids = @versions.map(&:whodunnit).compact.map(&:to_i)
    @members = Member.where(id: member_ids).index_by(&:id)
    @crop_wranglers = Role.crop_wranglers
  end

  private

  def authorize_admin!
    authorize! :wrangle, Crop
  end
end
