# frozen_string_literal: true

require 'json'

# Loads crop job templates from JSON files, as db/seeds does. A file is one
# crop's templates:
#
#   {
#     "crop": "tomato",
#     "templates": [
#       {
#         "name": "Growing tomatoes",
#         "applies_to": "cherry tomato",   (optional: a variety of the crop)
#         "season": "any",                 (any, spring_summer, autumn_winter)
#         "status": "draft",               (draft, published)
#         "steps": [
#           { "name": "Sow seeds indoors", "amount": 6, "unit": "weeks", "direction": "before",
#             "anchor": "planting_out", "repeat": "once", "external_uri": "https://example.com/sowing" }
#         ]
#       }
#     ]
#   }
#
# A step's amount defaults to 0, its unit to weeks, its direction to after, its
# anchor to planting_out and its repeat to once. A step can have an external_uri,
# a web address with more on how to do it. Steps are kept in the order written.
#
# Templates are only ever added: one that is already there, by crop and name, is
# left alone, so what a crop wrangler has changed is not undone by seeding again.
class CropJobTemplateImporter
  class Invalid < StandardError; end

  STEP_ATTRIBUTES = { 'name' => :name, 'amount' => :offset_amount, 'unit' => :offset_unit, 'direction' => :direction,
                      'anchor' => :anchor, 'repeat' => :repeat, 'external_uri' => :external_uri }.freeze

  def initialize(out: $stdout)
    @out = out
    @stats = Hash.new(0)
  end

  # Imports each file, returning how many templates were created, were already
  # there, or were skipped because their crop is not here.
  def import_files(paths)
    paths.each { |path| import_file(path) }
    @stats
  end

  def import_file(path)
    import(JSON.parse(File.read(path)), source: path)
  rescue JSON::ParserError => e
    raise Invalid, "#{path}: #{e.message}"
  end

  def import(data, source: 'data')
    crop = Crop.approved.find_by(name: data['crop'])
    return skip_crop(data['crop'], data['templates']) unless crop

    Array(data['templates']).each { |template| import_template(crop, template, source) }
    @stats
  end

  private

  def skip_crop(name, templates)
    @out.puts "  skipped #{Array(templates).size} template(s): no crop called #{name.inspect}"
    @stats[:skipped] += Array(templates).size
    @stats
  end

  def import_template(crop, data, source)
    owner = data['applies_to'] ? variety(crop, data['applies_to']) : crop
    return skip_variety(crop, data) unless owner

    if CropJobTemplate.exists?(crop: owner, name: data['name'])
      @stats[:existing] += 1
      return
    end

    template = build_template(owner, data)
    raise Invalid, "#{source}, #{data['name'].inspect} for #{crop.name}: #{template.errors.full_messages.to_sentence}" unless template.save

    @stats[:created] += 1
  end

  def build_template(owner, data)
    template = CropJobTemplate.new(crop: owner, **data.slice('name', 'season', 'status').symbolize_keys)
    Array(data['steps']).each_with_index do |step, index|
      template.steps.build(step_attributes(step).merge(position: index))
    end
    template
  end

  def step_attributes(step)
    STEP_ATTRIBUTES.each_with_object({}) { |(key, attribute), attributes| attributes[attribute] = step[key] if step.key?(key) }
  end

  def variety(crop, name)
    crop.varieties.approved.find_by(name:)
  end

  def skip_variety(crop, data)
    @out.puts "  skipped #{data['name'].inspect}: #{crop.name} has no variety called #{data['applies_to'].inspect}"
    @stats[:skipped] += 1
  end
end
