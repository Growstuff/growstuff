class PlantingWeatherLog < ActiveRecord::Base
  belongs_to :planting

  # Defines a JSON data type as weather_log
  # See http://edgeguides.rubyonrails.org/active_record_postgresql.html#json for how to query it
  # See http://openweathermap.org/current for data structure

end