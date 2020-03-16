# frozen_string_literal: true

module PhotosHelper
  def crop_image_path(crop)
    thumbnail_url(crop.default_photo)
  end

  def thumbnail_url(photo)
    if photo.nil?
      placeholder_image
    elsif photo.source == 'flickr'
      photo.fullsize_url
    else
      photo.thumbnail_url
    end
  end

  def garden_image_path(garden)
    photo_or_placeholder(garden)
  end

  def planting_image_path(planting)
    photo_or_placeholder(planting)
  end

  def harvest_image_path(harvest)
    photo_or_placeholder(harvest)
  end

  def seed_image_path(seed)
    photo_or_placeholder(seed)
  end

  def post_image_path(post)
    post.default_photo&.fullsize_url || post.crops.first&.default_photo&.fullsize_url || placeholder_image
  end

  private

  def photo_or_placeholder(item)
    if item.default_photo.present?
      item_photo(item)
    elsif item.respond_to?(:crop)
      crop_image_path(item.crop)
    else
      placeholder_image
    end
  end

  def item_photo(item)
    item.default_photo.fullsize_url
  end

  def placeholder_image
    'placeholder_600.png'
  end
end
