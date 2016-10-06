class Api::ApiController < ApplicationController
  include JSONAPI::ActsAsResourceController
  before_action :doorkeeper_authorize! # Require access token for all actions
end