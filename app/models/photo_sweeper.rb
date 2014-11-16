class PhotoSweeper < Sweeper
  observe Photo

  def after_create(photo)
    expire_fragment('interesting_plantings')
  end

  def after_destroy(photo)
    expire_fragment('interesting_plantings')
  end

end

