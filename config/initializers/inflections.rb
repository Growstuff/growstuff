# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format
# (all these examples are active by default):
# ActiveSupport::Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end
#
# These inflection rules are supported but not enabled by default:
# ActiveSupport::Inflector.inflections do |inflect|
#   inflect.acronym 'RESTful'
# end

ActiveSupport::Inflector.inflections do |inflect|
  inflect.plural 'square foot', 'square feet'
  inflect.plural 'broccoli', 'broccoli'
  inflect.plural 'kale', 'kale'
  inflect.plural 'squash', 'squash'
  inflect.plural 'bok choy', 'bok choy'
  inflect.plural 'achiote', 'achiote'
  inflect.plural 'alfalfa', 'alfalfa'
  inflect.plural 'allspice', 'allspice'
  inflect.plural 'spinach', 'spinach'
  inflect.plural 'garlic', 'garlic'
  inflect.plural 'licorice', 'licorice'
  inflect.plural 'lillipilli', 'lillipillies'
end
