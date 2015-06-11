class SensorsController < ApplicationController
  def index
    @sensors = Sensor.paginate(:page => params[:page])

    respond_to do |format|
      format.html # index.html.erb
    end
  end
end
