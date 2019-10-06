module SeedsHelper
  def display_seed_quantity(seed)
    seed.quantity.nil? ? 'seeds' : pluralize(seed.quantity, 'seed')
  end

  def display_seed_description(seed)
    if seed.description.present?
      return(
        truncate(seed.description, length: 130, separator: ' ', omission: '... ') do
          link_to 'Read more', seed_path(seed)
        end
      )
    end

    ''
  end
end
