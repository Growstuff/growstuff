module IconsHelper
  include FontAwesome::Sass::Rails::ViewHelpers

  def icon_for_model(event_model)
    send("#{event_model}_icon")
  end

  def timeline_icon
    icon('far', 'calendar')
  end

  def garden_icon
    image_icon 'home'
  end

  def planting_icon
    image_icon 'planting'
  end

  def member_icon
    icon('far', 'user')
  end

  def harvest_icon
    image_icon 'harvest'
  end

  def seed_icon
    image_icon 'seeds'
  end

  def comment_icon
    icon('far', 'comment')
  end

  def finished_icon
    icon('fas', 'calendar')
  end

  def edit_icon
    icon('fas', 'pencil-alt')
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

  def post_icon
    image_icon 'post'
  end

  def perennial_icon
    icon('fas', 'tree')
  end

  def planted_from_icon(planted_from)
    planted_from
  end

  def delete_association_icon
    icon('fas', 'backspace')
  end

  def like_icon
    icon('fas', 'heart')
  end

  def crop_icon(crop)
    if crop.svg_icon.present?
      image_tag(crop_path(crop, format: 'svg'), class: 'crop-icon')
    elsif crop.parent.present?
      crop_icon(crop.parent)
    else
      planting_icon
    end
  end

  def sunniness_icon(sunniness)
    case sunniness
    when 'sun'
      icon 'far', 'sun'
    when 'shade'
      icon 'fas', 'umbrella-beach'
    when 'semi-shade'
      icon 'fas', 'cloud-sun'
    else
      icon 'fas', 'question'
    end
  end

  def image_icon(icon)
    image_tag "icons/#{icon}.svg", class: 'img img-icon'
  end
end
