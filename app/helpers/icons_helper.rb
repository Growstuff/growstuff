# frozen_string_literal: true

module IconsHelper
  include FontAwesome::Sass::Rails::ViewHelpers

  def icon_for_model(event_model)
    send("#{event_model}_icon")
  end

  def cute_icon
    icons = %w(slug sprinkler bee ant hose grass rabbit slug-eating snail earth-worm insect watering-can
               wheelbarrow cat spiderweb bug butterfly ladybird stones)
    rand_num = rand(1..icons.size)
    icon = icons[rand_num - 1]
    image_tag("icons/#{icon}.svg", 'aria-hidden' => "true", class: 'img img-cute', alt: icon)
  end

  def timeline_icon
    image_icon 'timeline'
  end

  def garden_icon
    image_icon 'gardens'
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

  def growing_icon
    image_icon 'growing'
  end

  def seed_icon
    image_icon 'seeds'
  end

  def comment_icon
    icon('far', 'comment')
  end

  def finished_icon
    image_icon 'finish'
  end

  def edit_icon
    image_icon 'edit'
  end

  def delete_icon
    image_icon 'delete'
  end

  def add_photo_icon
    image_icon 'add-photo'
  end

  def photo_icon
    image_icon 'photo'
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

  def plant_part_icon(name)
    if File.exist? Rails.root.join('app', 'assets', 'images', 'icons', 'plant_parts', "#{name}.svg")
      image_tag "icons/plant_parts/#{name}.svg", class: 'img img-icon', 'aria-hidden' => "true"
    else
      planting_icon
    end
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
    image_tag "icons/#{icon}.svg", class: 'img img-icon', 'aria-hidden' => "true"
  end
end
