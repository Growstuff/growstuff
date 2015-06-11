class SensorsController < ApplicationController
  def index
    @sensors = Sensor.paginate(:page => params[:page])

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /sensors/new
  def new
    @sensor = Sensor.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end
end
