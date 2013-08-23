require 'rails'
require 'open-uri'
require 'json'

class Nominatim

  def self.geocode(place)
    if Rails.env.test?
      return stubs[place]
    end
    json = open(
      URI.escape("http://nominatim.openstreetmap.org/search/#{place}?format=json&limit=1"),
      "User-Agent" => Growstuff::Application.config.user_agent,
      "From" => Growstuff::Application.config.user_agent_email
    ).read()
    location = JSON.parse(json)
    if location && location[0]
      return {
        :latitude => location[0]['lat'],
        :longitude => location[0]['lon'],
        :boundingbox => location[0]['boundingbox'],
      }
    else
      return nil
    end
  end

  def self.stubs
    @stubs ||= {}
  end

  def self.add_stub(query_text, results)
    stubs[query_text] = results
  end
end
