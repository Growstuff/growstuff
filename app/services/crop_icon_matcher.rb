# frozen_string_literal: true

# Gives crops one of the app's crop icons by name, for crops that haven't had
# one chosen. Crops named like the plant an icon draws get it, and varieties
# then follow their parent crop, so tagging "tomato" covers every tomato.
#
# A crop with no parent to follow is also matched on the end of its name, so
# "cherry tomato" gets the tomato and "flat leaf parsley" the herb.
#
# Never replaces an icon a wrangler has already chosen.
class CropIconMatcher
  # Icon => the crop names it stands for, singular, lower case.
  MATCHES = {
    'avocado'          => %w(avocado),
    'banana'           => %w(banana plantain),
    'beans'            => ['bean', 'broad bean', 'fava bean', 'runner bean', 'green bean', 'french bean',
                           'soybean', 'soy bean', 'kidney bean', 'lima bean', 'borlotti bean'],
    'bell_pepper'      => ['bell pepper', 'capsicum', 'sweet pepper', 'pepper'],
    'blueberries'      => %w(blueberry),
    'broccoli'         => ['broccoli', 'cauliflower', 'romanesco', 'brussels sprout'],
    'brown_mushroom'   => ['shiitake', 'oyster mushroom'],
    'cactus'           => ['cactus', 'prickly pear', 'dragon fruit'],
    'carrot'           => %w(carrot parsnip),
    'cherries'         => %w(cherry),
    'chestnut'         => %w(chestnut),
    'coconut'          => %w(coconut),
    'cucumber'         => %w(cucumber gherkin zucchini courgette),
    'ear_of_corn'      => ['corn', 'sweet corn', 'sweetcorn', 'maize', 'popcorn'],
    'eggplant'         => %w(eggplant aubergine),
    'four_leaf_clover' => %w(clover alfalfa lucerne),
    'garlic'           => %w(garlic),
    'grapes'           => %w(grape),
    'green_apple'      => ['granny smith'],
    'herb'             => ['basil', 'parsley', 'coriander', 'cilantro', 'mint', 'spearmint', 'peppermint',
                           'thyme', 'oregano', 'marjoram', 'rosemary', 'sage', 'dill', 'tarragon',
                           'lemon balm', 'chervil', 'lovage', 'sorrel', 'bay', 'bay laurel', 'stevia',
                           'catnip', 'chamomile', 'anise', 'alexanders', 'lemongrass', 'borage'],
    'hibiscus'         => %w(hibiscus rosella),
    # Named ones too, or matching on the last word would make them bell peppers.
    'hot_pepper'       => ['chilli', 'chili', 'chile', 'chilli pepper', 'chili pepper', 'hot pepper',
                           'cayenne pepper', 'jalapeno', 'jalapeño', 'jalapeno pepper', 'jalapeño pepper',
                           'habanero', 'habanero pepper', 'tabasco pepper', 'serrano pepper',
                           'poblano pepper', 'ghost pepper', 'scotch bonnet', 'scotch bonnet pepper'],
    'hyacinth'         => %w(hyacinth lavender),
    'kiwi_fruit'       => %w(kiwifruit kiwi),
    'leafy_green'      => ['lettuce', 'spinach', 'kale', 'cabbage', 'silverbeet', 'chard', 'swiss chard',
                           'rocket', 'arugula', 'bok choy', 'pak choi', 'collard', 'collards',
                           'mustard greens', 'endive', 'radicchio', 'mizuna', 'watercress', 'celery'],
    'lemon'            => %w(lemon),
    'lime'             => %w(lime),
    'lotus'            => %w(lotus),
    'mango'            => %w(mango),
    'melon'            => %w(melon rockmelon cantaloupe honeydew muskmelon),
    'mushroom'         => %w(mushroom),
    'olive'            => %w(olive),
    'onion'            => ['onion', 'shallot', 'leek', 'spring onion', 'scallion', 'chives', 'chive'],
    'pea_pod'          => ['pea', 'snow pea', 'sugar snap pea', 'snap pea', 'mangetout'],
    'peach'            => %w(peach nectarine apricot plum),
    'peanuts'          => %w(peanut),
    'pear'             => %w(pear nashi),
    'pineapple'        => %w(pineapple),
    'potato'           => ['potato', 'sweet potato', 'kumara', 'yam', 'jerusalem artichoke'],
    'red_apple'        => %w(apple crabapple),
    'rose'             => %w(rose),
    'sheaf_of_rice'    => %w(rice wheat barley oat oats rye),
    'strawberry'       => %w(strawberry),
    'sunflower'        => %w(sunflower),
    'tangerine'        => %w(orange mandarin tangerine clementine grapefruit),
    'tomato'           => %w(tomato),
    'tulip'            => %w(tulip),
    'watermelon'       => %w(watermelon)
  }.freeze

  # Crop name => icon, for looking up.
  BY_NAME = MATCHES.flat_map { |icon, names| names.map { |name| [name, icon] } }.to_h.freeze

  def self.icon_for(name)
    key = name.to_s.downcase.strip
    BY_NAME[key] || BY_NAME[key.singularize]
  end

  # The same, but also trying the end of the name, longest first: "persian
  # lime", then "lime".
  def self.icon_for_last_words(name)
    words = name.to_s.downcase.split
    words.each_index.lazy.filter_map { |start| icon_for(words[start..].join(' ')) }.first
  end

  # Returns the crops it gave an icon, as {crop => icon}. With dry_run, says
  # what it would do and changes nothing.
  def call(dry_run: false)
    Crop.where(icon: [nil, '']).find_each.with_object({}) do |crop, assigned|
      icon = crop.parent_id ? self.class.icon_for(crop.name) : self.class.icon_for_last_words(crop.name)
      next if icon.nil?

      crop.update_column(:icon, icon) unless dry_run # rubocop:disable Rails/SkipsModelValidations
      assigned[crop] = icon
    end
  end
end
