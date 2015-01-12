json.data @crops do |crop|
  json.(crop, :id, :name)
  json.set! '@id', url_for(:only_path => false) + '/' + crop.id.to_s
  json.url crop_url(crop)
end

json.partial! 'api/v1/_partials/base'
