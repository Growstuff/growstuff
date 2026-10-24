# frozen_string_literal: true

# Where photos uploaded to the Growstuff photo library are kept, and the
# addresses they are shown from.
#
# A photo as a member sends it is kept privately, since it can hold where it was
# taken, until PhotoUploadJob has made the versions shown on the site. Those go
# under PUBLIC_PREFIX, which the S3 bucket's policy lets anyone read, so their
# addresses are known when the photo is created and never change.
module PhotoLibrary
  PUBLIC_PREFIX = 'photos/'
  VERSIONS = {
    fullsize:  { resize_to_limit: [1600, 1600] },
    thumbnail: { resize_to_fill: [300, 300] }
  }.freeze

  # The licences a member can choose for a photo they upload. The first, the
  # one the site's own data uses, is the default.
  LICENSES = {
    'CC BY-SA 4.0' => 'https://creativecommons.org/licenses/by-sa/4.0/',
    'CC BY 4.0'    => 'https://creativecommons.org/licenses/by/4.0/',
    'CC BY-NC 4.0' => 'https://creativecommons.org/licenses/by-nc/4.0/',
    'CC0 1.0'      => 'https://creativecommons.org/publicdomain/zero/1.0/'
  }.freeze

  CONTENT_TYPES = %w(image/jpeg image/png image/webp image/heic image/heif).freeze
  MAX_FILE_SIZE = 20.megabytes
  # Bigger than any phone camera, small enough that one photo can't take all
  # the memory of the dyno processing it.
  MAX_PIXELS = 50_000_000

  def self.key(token, version)
    "#{PUBLIC_PREFIX}#{token}/#{version}.jpg"
  end

  def self.url(key)
    service = ActiveStorage::Blob.service
    if service.respond_to?(:bucket)
      service.bucket.object(key).public_url
    else
      # Files on disk, in development and test: PhotoLibraryFilesController.
      Rails.application.routes.url_helpers.photo_library_file_url(
        key.delete_prefix(PUBLIC_PREFIX), **Rails.application.config.action_mailer.default_url_options
      )
    end
  end
end
