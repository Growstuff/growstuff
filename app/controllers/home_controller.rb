# frozen_string_literal: true

class HomeController < ApplicationController
  skip_authorize_resource
  respond_to :html

  def index
    # we were previously generating a lot of instance variables like
    # @members_count and @interesting_crops in here, but now we call
    # the relevant class methods directly in the view, so that fragment
    # caching will be effective.
  end
end
