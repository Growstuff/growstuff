# Defines a JSON data type as weather_log
# See http://edgeguides.rubyonrails.org/active_record_postgresql.html#json for how to query it
# See http://openweathermap.org/current for documentation

# Example call: http://api.openweathermap.org/data/2.5/weather?q=London,uk&appid=df8abc00e3162fbd98bc48063cc6c4b5
#  {  
#   "coord":{  
#     "lon":-0.13,
#     "lat":51.51
#   },
#   "weather":[  
#     {  
#       "id":800,
#       "main":"Clear",
#       "description":"clear sky",
#       "icon":"01d"
#     }
#   ],
#   "base":"stations",
#   "main":{  
#     "temp":281.83,
#     "pressure":1025,
#     "humidity":61,
#     "temp_min":280.15,
#     "temp_max":283.15
#   },
#   "visibility":10000,
#   "wind":{  
#     "speed":5.7,
#     "deg":300
#   },
#   "clouds":{  
#     "all":0
#   },
#   "dt":1491808800,
#   "sys":{  
#     "type":1,
#     "id":5091,
#     "message":0.0097,
#     "country":"GB",
#     "sunrise":1491801287,
#     "sunset":1491850179
#   },
#   "id":2643743,
#   "name":"London",
#   "cod":200
# }
class PlantingWeatherLog < ActiveRecord::Base
  belongs_to :planting
end