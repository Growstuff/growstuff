class ScientificNameSweeper < ActionController::Caching::Sweeper
  observe ScientificName

  def after_create(scientific_name)
    expire_fragment("crop_image_#{scientific_name.crop.id}")
  end

  def after_update(scientific_name)
    expire_fragment("crop_image_#{scientific_name.crop.id}")
  end

  def after_destroy(scientific_name)
    expire_fragment("crop_image_#{scientific_name.crop.id}")
  end

end

