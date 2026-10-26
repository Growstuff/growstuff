# frozen_string_literal: true

# Makes the versions of an uploaded photo that the site shows, then deletes the
# photo as sent. The versions are JPEGs without the photo's metadata, so they
# don't publish where it was taken; the date it was taken is kept on the photo.
# A file that turns out not to be an image, or is too big, takes its photo with it.
class PhotoUploadJob < ApplicationJob
  discard_on ActiveJob::DeserializationError

  def perform(photo)
    return unless photo.upload.attached?

    # Here rather than at the top, so the app still starts without libvips.
    require 'image_processing/vips'

    photo.upload.open do |file|
      image = Vips::Image.new_from_file(file.path)
      return photo.destroy if image.width * image.height > PhotoLibrary::MAX_PIXELS

      PhotoLibrary::VERSIONS.each { |version, steps| store(photo, version, file.path, steps) }
      photo.update!(date_taken: photo.date_taken || date_taken(image))
    end
    photo.upload.purge
  rescue Vips::Error
    photo.destroy
  end

  private

  def store(photo, version, path, steps)
    attachment = photo.public_send(:"#{version}_image")
    attachment.purge if attachment.attached? # from an earlier try
    processed = ImageProcessing::Vips.source(path)
      .apply(steps)
      .custom { |image| image.has_alpha? ? image.flatten(background: 255) : image }
      .convert('jpg')
      .saver(strip: true, quality: 85)
      .call
    attachment.attach(
      ActiveStorage::Blob.create_and_upload!(io: processed, filename: "#{version}.jpg", content_type: 'image/jpeg',
                                             key: PhotoLibrary.key(photo.source_id, version))
    )
  end

  def date_taken(image)
    return unless image.get_fields.include?('exif-ifd2-DateTimeOriginal')

    Time.zone.strptime(image.get('exif-ifd2-DateTimeOriginal')[0, 19], '%Y:%m:%d %H:%M:%S')
  rescue ArgumentError
    nil
  end
end
