module IconsHelper
  include FontAwesome::Sass::Rails::ViewHelpers
  def garden_icon
    icon('far', 'square')
  end

  def planting_icon
    icon('fas', 'seedling')
  end

  def harvest_icon
    icon('fas', 'carrot')
  end

  def seed_icon
    icon('fas', 'heart')
  end

  def finished_icon
    icon('fas', 'calendar')
  end

  def edit_icon
    icon('far', 'edit')
  end

  def delete_icon
    icon('fas', 'trash-alt')
  end

  def photo_icon
    icon('fas', 'camera-retro')
  end

  def crop_icon(crop)
    path = "icons/crops/#{crop.name}.svg"
    return image_url(path, height: 25) if icon_exists?(path)
    image_url(crop_image_path(crop), height: 25)
  end

  def icon_exists?(path)
    if Rails.configuration.assets.compile
      Rails.application.precompiled_assets.include? path
    else
      Rails.application.assets_manifest.assets[path].present?
    end
  end
end
