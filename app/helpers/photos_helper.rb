module PhotosHelper
  def crop_image_path(crop, full_size: false)
    if crop.default_photo.present?
      photo = crop.default_photo
      full_size ? photo.fullsize_url : photo.thumbnail_url
    else
      placeholder_image
    end
  end

  def garden_image_path(garden, full_size: false)
    if garden.default_photo.present?
      photo = garden.default_photo
      full_size ? photo.fullsize_url : photo.thumbnail_url
    else
      placeholder_image
    end
  end

  def planting_image_path(planting, full_size: false)
    if planting.photos.present?
      photo = planting.photos.order(date_taken: :desc).first
      full_size ? photo.fullsize_url : photo.thumbnail_url
    else
      placeholder_image
    end
  end

  def harvest_image_path(harvest, full_size: false)
    if harvest.photos.present?
      photo = harvest.photos.order(date_taken: :desc).first
      full_size ? photo.fullsize_url : photo.thumbnail_url
    elsif harvest.planting.present?
      planting_image_path(harvest.planting, full_size: full_size)
    else
      placeholder_image
    end
  end

  def seed_image_path(seed, full_size: false)
    if seed.default_photo.present?
      photo = seed.default_photo
      full_size ? photo.fullsize_url : photo.thumbnail_url
    elsif seed.crop.default_photo.present?
      photo = seed.crop.default_photo
      full_size ? photo.fullsize_url : photo.thumbnail_url
    else
      placeholder_image
    end
  end

  private

  def placeholder_image
    'placeholder_150.png'
  end
end
