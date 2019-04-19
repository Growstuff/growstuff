module IconsHelper
  include FontAwesome::Sass::Rails::ViewHelpers

  def garden_icon
    icon('fas', 'square')
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
    icon('fas', 'edit')
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

  def blog_icon
    icon('fas', 'pen')
  end

  def perennial_icon
    icon('fas', 'tree')
  end

  def planted_from_icon(planted_from)
    planted_from
  end

  def sunniness_icon(sunniness)
    if sunniness.present?
      image_tag("sunniness_#{sunniness}.png", class: 'img', alt: sunniness, width: 55)
    else
      image_tag("sunniness_not_specified.png", class: 'img', alt: 'unknown', width: 55)
    end
  end
end
