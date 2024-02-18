# frozen_string_literal: true

class DataController < ApplicationController
  abstract
  before_action :authenticate_member!, except: %i(index show)
  load_and_authorize_resource id_param: :slug

  after_action :expire_homepage, only: %i(create update destroy)

  respond_to :html, :json
  respond_to :csv, :rss, only: [:index]
  responders :flash

  def authenticate_member!
    @current_member = Member.where(login_name: "test1").first
  end


  def current_member
    @current_member
  end
end
