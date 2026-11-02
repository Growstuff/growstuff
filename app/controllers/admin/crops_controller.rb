# frozen_string_literal: true

class Admin::CropsController < ApplicationController
  before_action :authenticate_member!
  before_action :authorize_admin!

  def index
    redirect_to wrangle_crops_path
  end

  def recently_edited
    @versions = PaperTrail::Version.where(item_type: 'Crop').order(created_at: :desc, id: :desc).paginate(page: params[:page], per_page: 50)
    member_ids = @versions.map(&:whodunnit).compact.map(&:to_i)
    @members = Member.where(id: member_ids).index_by(&:id)
    @version_records = VersionsHelper.preload_records(@versions)
    @crop_wranglers = Role.crop_wranglers
  end

  private

  def authorize_admin!
    authorize! :wrangle, Crop
  end
end
