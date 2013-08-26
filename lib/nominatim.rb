require 'open-uri'
require 'json'

class Nominatim

  # class-level instance variable, see
  # http://www.railstips.org/blog/archives/2006/11/18/class-and-instance-variables-in-ruby/
  class << self
    attr_accessor :in_testing
    attr_accessor :user_agent
    attr_accessor :user_agent_email
  end
  @in_testing = false

  def self.geocode(place)
    if self.in_testing
      return stubs[place]
    end
    json = open(
      URI.escape("http://nominatim.openstreetmap.org/search/#{place}?format=json&limit=1"),
      "User-Agent" => user_agent,
      "From" => user_agent_email
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
