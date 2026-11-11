# frozen_string_literal: true

module Admin
  # Global switches and individual member grants, managed only by admins.
  class FeaturesController < ApplicationController
    before_action :authenticate_member!
    before_action { authorize! :manage, :all }

    def index
      @features = Feature.all
    end

    def update
      feature = Feature.find(params[:id])
      feature.enabled = ActiveModel::Type::Boolean.new.cast(params[:enabled])
      notice = t(".#{feature.enabled? ? 'enabled' : 'disabled'}", feature: t("admin.features.names.#{feature.name}"))
      redirect_to admin_features_path, notice:
    end

    def add_member
      feature = Feature.find(params[:id])
      member = Member.kept.find_by(login_name: params[:login_name].to_s.strip)
      return redirect_to admin_features_path, alert: t('admin.features.member_not_found') unless member

      feature.enable_member(member)
      redirect_to admin_features_path
    end

    def remove_member
      feature = Feature.find(params[:id])
      feature.disable_member(Member.find(params[:member_id]))
      redirect_to admin_features_path
    end
  end
end
