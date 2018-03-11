module PhotosHelper
  def crop_image_path(crop)
    if crop.default_photo.present?
      crop.default_photo.thumbnail_url
    else
      default_image
    end
  end

  def planting_image_path(planting)
    if planting.photos.present?
      planting.photos.first.thumbnail_url
    else
      default_image
    end
  end

  def harvest_image_path(harvest)
    if harvest.photos.present?
      harvest.photos.first.thumbnail_url
    else
      default_image
    end
  end

  def seed_image_path(seed)
    if seed.default_photo
      seed.default_photo.thumbnail_url
    else
      default_image
    end
  end

  private

  def default_image
    'placeholder_150.png'
  end
end
