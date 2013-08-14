class CropSweeper < ActionController::Caching::Sweeper
  observe Crop

  def after_create(crop)
    expire_fragment('homepage_stats')
  end

  def after_update(crop)
    expire_fragment("crop_image_#{crop.id}")
  end

  def after_destroy(crop)
    expire_fragment('homepage_stats')
  end

end

