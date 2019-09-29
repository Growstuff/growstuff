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

  def seeds_active_tickbox_path(owner, show_all)
    show_inactive_tickbox_path('seeds', owner, show_all)
  end
end
