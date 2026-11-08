# frozen_string_literal: true

# Adds a public, Creative Commons photo from Flickr to a crop, saying what it shows
# (a planting, a harvest or seeds) without tying it to any one of them. The photo
# belongs to cropbot, as the crop's own photos are the site's rather than a member's,
# and credits its photographer. If the photo is already here, from anyone, it is
# only attached to the crop.
#
# Raises FlickrPublicPhoto::Rejected, with a reason to show, when Flickr will not
# give the photo up, and ActiveRecord::RecordInvalid when it cannot be saved.
class AddCropPhoto
  def initialize(crop, url:, kind:)
    @crop = crop
    @url = url
    @kind = kind
  end

  def call
    attributes = FlickrPublicPhoto.new(@url).attributes
    photo = Photo.find_or_initialize_by(source: 'flickr', source_id: attributes[:source_id])
    photo.assign_attributes(attributes.merge(title: attributes[:title] || @crop.name, owner: cropbot)) if photo.new_record?
    photo.save!
    photo.photo_associations.find_or_initialize_by(photographable: @crop).update!(label: @kind)
    photo
  end

  private

  def cropbot
    Member.find_by!(login_name: 'cropbot')
  end
end
