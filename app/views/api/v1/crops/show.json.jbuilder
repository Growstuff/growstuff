json.data do
  json.(@crop, :id, :name, :creator_id, :en_wikipedia_url)
  json.set! '@id', url_for(:only_path => false)
  json.url crop_url(@crop)
  json.set! '@type', 'Crop'
end

json.partial! 'api/v1/_partials/base'
