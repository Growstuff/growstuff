# frozen_string_literal: true

module SeedsHelper
  def plantings_for_seed_source(member)
    plantings = member.plantings.map do |planting|
      [planting.crop.name, planting.id]
    end
    plantings << ['Other source', 'other']
  end

  def display_seed_quantity(seed)
    if seed.quantity.nil?
      'seeds'
    else
      pluralize(seed.quantity, 'seed')
    end
  end

  def display_seed_description(seed)
    if seed.description.present?
      return truncate(seed.description, length: 130, separator: ' ', omission: '... ') do
        link_to "Read more", seed_path(seed)
      end
    end

    ''
  end
end
