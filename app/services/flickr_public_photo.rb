# frozen_string_literal: true

# Looks up one photo on Flickr from its web address, with Flickr's public API and
# no member's Flickr account, and checks it may be shown here: public, and under a
# Creative Commons licence. Gives the attributes for a Photo.
#
#   FlickrPublicPhoto.new('https://www.flickr.com/photos/someone/12345/').attributes
#
# Raises FlickrPublicPhoto::Rejected, with a message to show the member, when the
# address is not a Flickr photo or the photo may not be used.
class FlickrPublicPhoto
  class Rejected < StandardError
    def initialize(reason)
      @reason = reason
      super(reason.to_s)
    end

    attr_reader :reason
  end

  # Flickr's licence ids that are Creative Commons: the six 2.0 licences, CC0, and
  # the Public Domain Mark. 0 is all rights reserved; 7 and 8 are not Creative Commons.
  CREATIVE_COMMONS_LICENSES = [1, 2, 3, 4, 5, 6, 9, 10].freeze

  # What to call each of them, as Flickr's search says only the id.
  LICENCE_CODES = {
    1 => 'CC BY-NC-SA 2.0', 2 => 'CC BY-NC 2.0', 3 => 'CC BY-NC-ND 2.0', 4 => 'CC BY 2.0',
    5 => 'CC BY-SA 2.0', 6 => 'CC BY-ND 2.0', 9 => 'CC0 1.0', 10 => 'Public Domain Mark 1.0'
  }.freeze

  BASE58 = '123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ'

  # photos/<user>/<id>, with anything after it, such as /in/album-...
  PAGE_PATH = %r{\A/photos/[^/]+/(?<id>\d+)}
  # The short links, flic.kr/p/<base58 of the id>
  SHORT_PATH = %r{\A/p/(?<code>[#{BASE58}]+)\z}o

  # The Flickr photo id in an address, or nil if it is not a Flickr photo's.
  def self.photo_id(url)
    uri = URI.parse(url.to_s.strip)
    return unless uri.is_a?(URI::HTTP)

    host = uri.host.to_s.downcase
    if host == 'flic.kr'
      code = SHORT_PATH.match(uri.path)&.[](:code)
      code ? decode_base58(code).to_s : nil
    elsif host == 'flickr.com' || host.end_with?('.flickr.com')
      PAGE_PATH.match(uri.path)&.[](:id)
    end
  rescue URI::InvalidURIError
    nil
  end

  def self.decode_base58(code)
    code.each_char.reduce(0) { |total, char| (total * 58) + BASE58.index(char) }
  end

  # Public, Creative Commons photos on Flickr matching some words, a page of 24 at a
  # time, for a wrangler to choose from. Each is a hash with the photo's page address,
  # which is what #attributes takes.
  def self.search(text, page: 1)
    flickr.photos.search(
      text: text, license: CREATIVE_COMMONS_LICENSES.join(','), privacy_filter: 1, media: 'photos',
      safe_search: 1, sort: 'relevance', extras: 'owner_name,license,date_taken', per_page: 24, page: page
    ).map do |photo|
      { title: photo.title.presence, owner_name: photo.ownername, thumbnail_url: FlickRaw.url_q(photo),
        licence: LICENCE_CODES[photo.license.to_i], taken: photo.datetaken.presence, url: FlickRaw.url_photopage(photo) }
    end
  rescue FlickRaw::FailedResponse, SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError, EOFError
    raise Rejected, :unavailable
  end

  def self.flickr
    FlickRaw.api_key = ENV.fetch('GROWSTUFF_FLICKR_KEY', nil)
    FlickRaw.shared_secret = ENV.fetch('GROWSTUFF_FLICKR_SECRET', nil)
    FlickRaw::Flickr.new
  end

  def initialize(url)
    @url = url
  end

  def attributes
    id = self.class.photo_id(@url)
    raise Rejected, :not_flickr if id.blank?

    info = fetch_info(id)
    raise Rejected, :not_public unless info.visibility.ispublic.to_i == 1
    raise Rejected, :not_creative_commons unless CREATIVE_COMMONS_LICENSES.include?(info.license.to_i)

    licence = licence_for(info.license)
    {
      source:        'flickr',
      source_id:     info.id,
      title:         info.title.presence,
      license_name:  licence.name,
      license_url:   licence.url.presence,
      thumbnail_url: FlickRaw.url_q(info),
      fullsize_url:  FlickRaw.url_z(info),
      link_url:      FlickRaw.url_photopage(info),
      date_taken:    info.dates.taken,
      author_name:   info.owner.realname.presence || info.owner.username,
      author_url:    FlickRaw.url_photostream(info)
    }
  end

  private

  # Flickr says "not found" and "permission denied" for photos that are private or gone.
  def fetch_info(id)
    flickr.photos.getInfo(photo_id: id)
  rescue FlickRaw::FailedResponse
    raise Rejected, :not_found
  rescue SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError, EOFError
    raise Rejected, :unavailable
  end

  def licence_for(id)
    flickr.photos.licenses.getInfo.find { |licence| licence.id.to_i == id.to_i } ||
      raise(Rejected, :unavailable)
  rescue FlickRaw::FailedResponse, SocketError, SystemCallError, Timeout::Error
    raise Rejected, :unavailable
  end

  def flickr
    @flickr ||= self.class.flickr
  end
end
