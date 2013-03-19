class HomeController < ApplicationController
  skip_authorize_resource
  def index
  end
end
