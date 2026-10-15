# frozen_string_literal: true

module SeedsHelper
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

  # Kilometres from the signed-in member to a seed's owner, or nil when either
  # has no location.
  def seed_km(seed)
    return unless current_member&.latitude && seed.owner.latitude

    Geocoder::Calculations.distance_between(
      [current_member.latitude, current_member.longitude],
      [seed.owner.latitude, seed.owner.longitude], units: :km
    )
  end

  # How far away that is, such as "12 km".
  def seed_distance(seed)
    km = seed_km(seed)
    "#{km.round} km" if km
  end

  # Packets nearest the signed-in member first; those with no known distance last.
  def nearest_first(packets)
    packets.sort_by { |seed| seed_km(seed) || Float::INFINITY }
  end
end
