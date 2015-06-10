class MeasurementController < ApplicationController
  # POST /measurement
  def create
    @measurement = Measurement.new(measurement_params)

    respond_to do |format|
      if @order_item.save
        format.html { redirect_to @measurement.order, notice: 'Added measurement' }

      else
        errors = @order_item.errors.empty? ?
          "There was a problem with your order." : @order_item.errors.full_messages.to_sentence
        format.html { redirect_to shop_path, alert: errors }
      end
    end
  end
end
