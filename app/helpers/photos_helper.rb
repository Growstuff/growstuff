module PhotosHelper
  def crop_image_path(crop)
    if crop.default_photo.present?
      crop.default_photo.thumbnail_url
    else
      placeholder_image
    end
  end

  def garden_image_path(garden)
    if garden.default_photo.present?
      garden.default_photo.thumbnail_url
    else
      placeholder_image
    end
  end

  def planting_image_path(planting)
    if planting.photos.present?
      planting.photos.first.thumbnail_url
    else
      placeholder_image
    end
  end

  def harvest_image_path(harvest)
    if harvest.photos.present?
      harvest.photos.first.thumbnail_url
    elsif harvest.planting.present? && harvest.planting.photos.present?
      harvest.planting.photos.first.thumbnail_url
    else
      placeholder_image
    end
  end

  def seed_image_path(seed)
    if seed.default_photo.present?
      seed.default_photo.thumbnail_url
    elsif seed.crop.default_photo.present?
      seed.crop.default_photo.thumbnail_url
    else
      placeholder_image
    end
  end

  private

  def placeholder_image
    'placeholder_150.png'
  end
end
