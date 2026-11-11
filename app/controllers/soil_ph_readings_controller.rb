# frozen_string_literal: true

class SoilPhReadingsController < ApplicationController
  before_action :authenticate_member!
  before_action :load_garden

  def new
    @soil_ph_reading = @garden.soil_ph_readings.new(measured_on: Time.zone.today)
  end

  def create
    @soil_ph_reading = @garden.soil_ph_readings.new(reading_params)
    if @soil_ph_reading.save
      redirect_to garden_path(@garden), notice: t('soil_ph_readings.saved')
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def load_garden
    @garden = Garden.friendly.find(params[:garden_slug])
    authorize! :record_soil_ph, @garden
  end

  def reading_params
    params.require(:soil_ph_reading).permit(:ph, :measured_on)
  end
end
