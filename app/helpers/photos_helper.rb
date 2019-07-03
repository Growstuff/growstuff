module PhotosHelper
  def crop_image_path(crop, full_size: false)
    photo_or_placeholder(crop, full_size: full_size)
  end

  def garden_image_path(garden, full_size: false)
    photo_or_placeholder(garden, full_size: full_size)
  end

  def planting_image_path(planting, full_size: false)
    photo_or_placeholder(planting, full_size: full_size)
  end

  def harvest_image_path(harvest, full_size: false)
    photo_or_placeholder(harvest, full_size: full_size)
  end

  def seed_image_path(seed, full_size: false)
    photo_or_placeholder(seed, full_size: full_size)
  end

  private

  def photo_or_placeholder(item, full_size: false)
    if item.default_photo.present?
      item_photo(item, full_size: full_size)
    else
      placeholder_image
    end
  end

  def item_photo(item, full_size:)
    photo = item.default_photo
    full_size ? photo.fullsize_url : photo.thumbnail_url
  end

  def placeholder_image
    'placeholder_150.png'
  end
end
