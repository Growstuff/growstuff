# frozen_string_literal: true

module MemberFlickr
  extend ActiveSupport::Concern

  included do
    # Authenticates against Flickr and returns an object we can use for subsequent api calls
    def flickr
      if @flickr.nil?
        flickr_auth = auth('flickr')
        if flickr_auth
          FlickRaw.api_key = ENV['GROWSTUFF_FLICKR_KEY']
          FlickRaw.shared_secret = ENV['GROWSTUFF_FLICKR_SECRET']
          @flickr = FlickRaw::Flickr.new
          @flickr.access_token = flickr_auth.token
          @flickr.access_secret = flickr_auth.secret
        end
      end
      @flickr
    end

    # Fetches a collection of photos from Flickr
    # Returns a [[page of photos], total] pair.
    # Total is needed for pagination.
    def flickr_photos(page_num = 1, set = nil)
      result = if set
                 flickr.photosets.getPhotos(
                   photoset_id: set,
                   page:        page_num,
                   per_page:    30
                 )
               else
                 flickr.people.getPhotos(
                   user_id:  'me',
                   page:     page_num,
                   per_page: 30
                 )
               end
      return [result.photo, result.total] if result

      [[], 0]
    end

    # Returns a hash of Flickr photosets' ids and titles
    def flickr_sets
      sets = {}
      flickr.photosets.getList.each do |p|
        sets[p.title] = p.id
      end
      sets
    end
  end
end
