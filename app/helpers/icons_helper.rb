module IconsHelper
  include FontAwesome::Sass::Rails::ViewHelpers

  def icon_for_model(event_model)
    send("#{event_model}_icon")
  end

  def trade_icon
    icon('fas', 'exchange-alt')
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
    icon('fas', 'thumbs-up')
  end

  def sunniness_icon(sunniness)
    if sunniness.present?
      image_tag("sunniness_#{sunniness}.png", class: 'img', alt: sunniness, width: 55)
    else
      image_tag("sunniness_not_specified.png", class: 'img', alt: 'unknown', width: 55)
    end
  end

  def image_icon(icon)
    image_tag "icons/#{icon}.svg", class: 'img img-icon'
  end
end
