json.data do
  json.(@crop, :id, :name, :creator_id, :en_wikipedia_url)
end

json.partial! 'api/v1/_partials/base'
