# frozen_string_literal: true

module Admin
  # The features admins can switch on and off for everyone.
  class FeaturesController < ApplicationController
    before_action :authenticate_member!
    before_action { authorize! :manage, :all }

    def index
      @features = Feature.all
    end

    def update
      feature = Feature.find(params[:id])
      feature.enabled = ActiveModel::Type::Boolean.new.cast(params[:enabled])
      redirect_to admin_features_path, notice: t(".#{feature.enabled? ? 'on' : 'off'}", feature: t("admin.features.names.#{feature.name}"))
    end
  end
end
