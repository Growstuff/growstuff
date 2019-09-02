module PhotosHelper
  def crop_image_path(crop)
    if crop.default_photo.present?
      crop.default_photo.fullsize_url
    elsif crop.of_photo.present?
      crop.of_photo
    else
      photo_or_placeholder(crop)
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

  private

  def photo_or_placeholder(item)
    if item.default_photo.present?
      item_photo(item)
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
