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

  def seedling_icon
    icon('fas', 'seedling')
  end

  def perennial_icon
    icon('fas', 'tree')
  end

  def planted_from_icon(planted_from)
    planted_from
  end

  def sunniness_icon(sunniness)
    image_tag("sunniness_#{sunniness}.png", class: 'img', alt: sunniness)
  end
end
