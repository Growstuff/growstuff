# frozen_string_literal: true

# The OpenAPI description of /api/v1, built from the Graphiti resources so that it cannot drift from the API.
# Served to Swagger UI at /api-docs/v1/swagger.json.
class ApiDocs
  SCALARS = {
    'string'      => { type: 'string' },
    'integer'     => { type: 'integer' },
    'integer_id'  => { type: 'integer' },
    'float'       => { type: 'number', format: 'float' },
    'big_decimal' => { type: 'string', format: 'decimal' },
    'boolean'     => { type: 'boolean' },
    'date'        => { type: 'string', format: 'date' },
    'datetime'    => { type: 'string', format: 'date-time' },
    'hash'        => { type: 'object' }
  }.freeze

  ERRORS = {
    '400' => 'The request could not be understood, for example an unknown filter, sort or include.',
    '401' => 'A write was attempted without a valid API token.',
    '403' => 'The token holder may not do this to this record.',
    '404' => 'No such record.',
    '422' => 'The record is not valid. The errors say which attributes are at fault.'
  }.freeze

  def self.openapi
    new(Graphiti::Schema.generate).openapi
  end

  def initialize(schema)
    @schema = schema
    @resources = schema[:resources].index_by { |resource| resource[:name] }
  end

  def openapi
    {
      openapi:    '3.0.3',
      info:       { title: 'Growstuff API', version: 'v1', description: description },
      servers:    [{ url: Rails.configuration.x.api_base_url }],
      paths:      paths,
      components: { securitySchemes: { bearerAuth: { type: 'http', scheme: 'bearer' } }, schemas: schemas }
    }
  end

  private

  def description
    <<~TEXT
      A JSON:API (https://jsonapi.org) interface to Growstuff. Reading is open to everyone; creating, changing and
      deleting need an API token from your account settings, sent as `Authorization: Bearer <token>`.
      Attribute and filter names are dashed (`planted-at`, `filter[owner-id]`).
    TEXT
  end

  def paths
    @schema[:endpoints].each_with_object({}) do |(path, endpoint), paths|
      actions = endpoint[:actions].transform_values { |action| @resources[action[:resource]] }
      collection = actions.slice(:index, :create, :search).map { |name, resource| [verb(name), operation(name, resource)] }
      member = actions.slice(:show, :update, :destroy).map { |name, resource| [verb(name), operation(name, resource)] }
      paths[path.to_s] = collection.to_h if collection.any?
      paths["#{path}/{id}"] = member.to_h.merge(parameters: [id_parameter]) if member.any?
    end
  end

  def verb(action)
    { index: :get, search: :get, show: :get, create: :post, update: :patch, destroy: :delete }.fetch(action)
  end

  def operation(action, resource)
    type = resource[:type]
    operation = { tags: [type], summary: summary(action, type), responses: responses(action, resource) }
    operation[:parameters] = parameters(action, resource)
    operation[:security] = [{ bearerAuth: [] }] if %i(create update destroy).include?(action)
    operation[:requestBody] = request_body(action, resource) if %i(create update).include?(action)
    operation.compact
  end

  def summary(action, type)
    { index: "List #{type}", search: "Search #{type} by name", show: "Get one of #{type}",
      create: "Create one of #{type}", update: "Change one of #{type}", destroy: "Delete one of #{type}" }.fetch(action)
  end

  def parameters(action, resource)
    case action
    when :index then filter_parameters(resource) + [sort_parameter(resource), include_parameter(resource)] + page_parameters(resource)
    when :search then [term_parameter] + page_parameters(resource)
    when :show then [include_parameter(resource)]
    end
  end

  def id_parameter
    { name: 'id', in: 'path', required: true, schema: { type: 'integer' } }
  end

  def term_parameter
    { name: 'term', in: 'query', required: true, schema: { type: 'string' }, description: 'Words from the crop\'s name' }
  end

  def filter_parameters(resource)
    resource[:filters].map do |name, filter|
      extra = filter[:operators] - ['eq']
      description = +'Several values can be given, separated by commas.'
      if extra.many?
        description << " Also `filter[#{dashed(name)}][#{extra.first}]` and #{extra.drop(1).map do |op|
          "`#{op}`"
        end.to_sentence}."
      end
      # Filters that take a list are strings; those that take one value (booleans) are that value.
      schema = filter[:single] ? scalar(filter[:type]) : { type: 'string' }
      { name: "filter[#{dashed(name)}]", in: 'query', required: false, schema: schema, description: description }
    end
  end

  def sort_parameter(resource)
    names = resource[:sorts].keys.map { |name| dashed(name) }
    { name: 'sort', in: 'query', required: false, schema: { type: 'string' },
      description: "Comma separated, with `-` in front to reverse. One of: #{names.map { |n| "`#{n}`" }.to_sentence}." }
  end

  def include_parameter(resource)
    names = resource[:relationships].keys
    { name: 'include', in: 'query', required: false, schema: { type: 'string' },
      description: "Related records to send as well, comma separated. One of: #{names.map { |n| "`#{n}`" }.to_sentence}." }
  end

  def page_parameters(resource)
    max = ApplicationResource.max_page_size
    [
      { name: 'page[number]', in: 'query', required: false, schema: { type: 'integer', minimum: 1 }, description: 'Which page, from 1.' },
      { name: 'page[size]', in: 'query', required: false, schema: { type: 'integer', minimum: 1, maximum: max },
        description: "How many to a page, up to #{max}. Defaults to #{resource[:default_page_size]}. " \
                     '`page[limit]` and `page[offset]` also work.' }
    ]
  end

  def responses(action, resource)
    type = resource[:type]
    ok = case action
         when :destroy then { '204' => { description: 'Deleted' } }
         when :create then { '201' => document("A new #{type.singularize}", type) }
         when :index, :search then { '200' => document("A page of #{type}", type, many: true) }
         else { '200' => document(type.singularize.capitalize, type) }
         end
    errors = ERRORS.slice(*error_codes(action)).transform_values { |text| { description: text } }
    ok.merge(errors)
  end

  def error_codes(action)
    case action
    when :index, :search then %w(400)
    when :show then %w(400 404)
    when :create then %w(400 401 403 422)
    else %w(401 403 404 422)
    end
  end

  def document(description, type, many: false)
    resource = { '$ref' => "#/components/schemas/#{schema_name(type)}" }
    data = many ? { type: 'array', items: resource } : resource
    { description: description,
      content:     { 'application/vnd.api+json' => { schema: { type: 'object', properties: {
        data: data, included: { type: 'array', items: { type: 'object' } },
        links: { type: 'object', description: 'first, prev, next and last pages' }
      } } } } }
  end

  # Changing a record says which one, as well as what it is.
  def request_body(action, resource)
    properties = { type: { type: 'string', enum: [resource[:type]] }, attributes: writable_attributes(resource),
                   relationships: writable_relationships(resource) }
    properties[:id] = { type: 'string' } if action == :update
    required = action == :update ? %w(type id) : %w(type)
    { required: true, content: { 'application/vnd.api+json' => { schema: { type: 'object', properties: {
      data: { type: 'object', required: required, properties: properties.compact }
    } } } } }
  end

  def schemas
    @resources.values.to_h do |resource|
      [schema_name(resource[:type]), {
        type:       'object',
        properties: {
          id: { type: 'string' }, type: { type: 'string', enum: [resource[:type]] },
          attributes: readable_attributes(resource), relationships: relationships(resource)
        }
      }]
    end
  end

  def schema_name(type)
    type.singularize.camelize
  end

  def readable_attributes(resource)
    attributes_schema(resource, nullable: true) { |attribute| attribute[:readable] }
  end

  def writable_attributes(resource)
    attributes_schema(resource) { |attribute| attribute[:readable] && attribute[:writable] }
  end

  # The `id` is the resource's own, not one of its attributes. Anything can be empty in a response, but not in a request.
  def attributes_schema(resource, nullable: false)
    chosen = resource[:attributes].select { |name, attribute| name != :id && yield(attribute) }
    { type: 'object', properties: chosen.to_h { |name, attribute| [dashed(name), attribute_schema(attribute, nullable: nullable)] } }
  end

  # A belongs_to is written through its foreign key, which the API shows only as a relationship.
  def writable_relationships(resource)
    writable = resource[:relationships].select do |name, relationship|
      relationship[:type] == 'belongs_to' && resource.dig(:attributes, :"#{name}_id", :writable)
    end
    return if writable.empty?

    { type: 'object', properties: writable.to_h { |name, relationship| [name.to_s, linkage(relationship)] } }
  end

  def relationships(resource)
    { type: 'object', description: 'Each has a `links.related` URL to follow; `data` is sent for the ones asked for with `include`.',
      properties: resource[:relationships].keys.to_h { |name| [name.to_s, { type: 'object' }] } }
  end

  def linkage(relationship)
    target = @resources[relationship[:resource]][:type]
    { type: 'object', properties: { data: { type: 'object', properties: {
      type: { type: 'string', enum: [target] }, id: { type: 'string' }
    } } } }
  end

  def attribute_schema(attribute, nullable:)
    scalar(attribute[:type]).merge(description: attribute[:description], nullable: (true if nullable)).compact
  end

  def scalar(type)
    SCALARS.fetch(type.to_s) do
      if type.to_s.start_with?('array_of')
        { type:  'array',
          items: SCALARS.fetch(type.to_s.delete_prefix('array_of_').singularize,
                               { type: 'string' }) }
      else
        { type: 'string' }
      end
    end
  end

  def dashed(name)
    name.to_s.dasherize
  end
end
