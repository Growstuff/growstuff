# frozen_string_literal: true

# Turns what someone typed, or where their browser says they are, into a short
# list of named places with coordinates for them to choose from.
#
# Used by the "tell us where you garden" dialog. Nominatim asks that clients
# do not search as someone types, so callers search on request, and results
# are cached so repeating a search costs nothing.
class PlaceSuggester
  LIMIT = 6

  def self.search(query)
    query = query.to_s.squish.first(100)
    return [] if query.length < 2

    cached(['place-search', query.downcase]) { format(Geocoder.search(query, params: { limit: LIMIT, addressdetails: 1 })) }
  end

  def self.reverse(latitude, longitude)
    cached(['place-reverse', latitude.round(2), longitude.round(2)]) do
      format(Geocoder.search([latitude, longitude], params: { zoom: 10, addressdetails: 1 }))
    end
  end

  def self.cached(key, &)
    Rails.cache.fetch(key, expires_in: 1.day, skip_nil: true, &)
  rescue Geocoder::Error, Timeout::Error, SocketError
    []
  end

  def self.format(results)
    results.filter_map { |result| place(result) }.uniq { |place| place[:name] }.first(LIMIT)
  end

  # "Wellington, New Zealand": the place, the region when it differs, the country.
  def self.place(result)
    address = result.data['address']
    address = {} unless address.is_a?(Hash)
    name = result.data['name'].presence || address.values_at('city', 'town', 'village', 'suburb', 'county', 'state').compact.first
    return if name.blank? || result.latitude.blank? || result.longitude.blank?

    parts = [name, address['state'], address['country']].compact_blank.uniq
    { name: parts.join(', '), latitude: result.latitude.to_f, longitude: result.longitude.to_f }
  end
  private_class_method :place, :cached, :format
end
