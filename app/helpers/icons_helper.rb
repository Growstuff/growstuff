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

  def copy_icon
    icon('far', 'copy')
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

  def activity_icon
    icon('fas', 'truck-pickup')
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
      image_tag "icons/plant_parts/#{name}.svg", class: 'img img-icon', 'aria-hidden' => "true", alt: name
    else
      planting_icon
    end
  end

  def crop_icon(crop)
    if crop.svg_icon.present?
      image_tag(crop_path(crop, format: 'svg'), class: 'crop-icon', alt: crop)
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
    image_tag "icons/#{icon}.svg", class: 'img img-icon', 'aria-hidden' => "true", alt: icon
  end

  # Line icons for the menu drawer and the record action menus. Green by default
  # (see .menu-icon); a danger item overrides it to match its text.
  MENU_ICONS = {
    garden: '<path d="M3 20h18"/><path d="M6 20V10M12 20V6M18 20v-8"/><path d="M4 10h4M10 6h4M16 12h4"/>',
    planting: '<path d="M12 21v-8"/><path d="M12 13c0-4-3-6-7-6 0 4 3 6 7 6z"/><path d="M12 15c0-3 2-5 6-5 0 3-2 5-6 5z"/>',
    harvest: '<path d="M3 10h18l-2 10H5z"/><path d="M8 10l3-6M16 10l-3-6"/>',
    seeds: '<path d="M12 3c4 3 6 7 6 10a6 6 0 0 1-12 0c0-3 2-7 6-10z"/>',
    people: '<circle cx="9" cy="8" r="3"/><path d="M3 20c0-3.5 2.7-6 6-6s6 2.5 6 6"/><circle cx="17" cy="9" r="2.5"/><path d="M17 14c2.5 0 4 2 4 5"/>',
    crop: '<path d="M5 19C5 10 10 5 20 4c0 10-5 15-14 15z"/><path d="M5 19l8-8"/>',
    activity: '<rect x="4" y="5" width="16" height="15" rx="2"/><path d="M4 10h16M9 3v4M15 3v4"/>',
    post: '<path d="M5 4h14v16H5z"/><path d="M8 9h8M8 13h8M8 17h5"/>',
    inbox: '<path d="M4 13l2-8h12l2 8"/><path d="M4 13v6h16v-6h-5l-1 2h-4l-1-2z"/>',
    edit: '<path d="M4 20l1-4L16 5l3 3L8 19z"/><path d="M14 7l3 3"/>',
    delete: '<path d="M4 7h16"/><path d="M9 7V4h6v3"/><path d="M6 7l1 13h10l1-13"/><path d="M10 11v6M14 11v6"/>',
    add_photo: '<path d="M4 8h3l2-3h6l2 3h3v11H4z"/><circle cx="12" cy="13" r="3.5"/>',
    finish: '<circle cx="12" cy="12" r="8"/><path d="M8.5 12.5l2.5 2.5 4.5-5"/>',
    copy: '<rect x="8" y="8" width="12" height="12" rx="2"/><path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2"/>',
    archive: '<path d="M4 7h16v4H4z"/><path d="M6 11v9h12v-9"/><path d="M10 15h4"/>',
    add: '<path d="M12 5v14M5 12h14"/>',
    download: '<path d="M12 4v11M7 11l5 5 5-5"/><path d="M5 20h14"/>',
    sign_out: '<path d="M10 4H5v16h5"/><path d="M15 8l4 4-4 4M19 12H9"/>'
  }.freeze

  def menu_icon(name)
    tag.svg(MENU_ICONS.fetch(name).html_safe, class: 'menu-icon', width: 22, height: 22, viewBox: '0 0 24 24', fill: 'none',
                                              stroke: 'currentColor', 'stroke-width': 1.8, 'stroke-linecap': 'round',
                                              'stroke-linejoin': 'round', 'aria-hidden': 'true')
  end
end
