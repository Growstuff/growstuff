# frozen_string_literal: true

class ApplicationResource < Graphiti::Resource
  self.abstract_class = true
  self.adapter = Graphiti::Adapters::ActiveRecord
  self.base_url = Rails.configuration.x.api_base_url
  self.endpoint_namespace = '/api/v1'
  self.default_page_size = 10
  self.max_page_size = 100

  # The adapter pages with Kaminari, which this app doesn't use.
  paginate do |scope, current_page, per_page, _context, offset|
    scope.limit(per_page).offset(offset || ((current_page - 1) * per_page))
  end

  # Writes belong to the member holding the token, and are theirs to make. The hooks run once the attributes are
  # assigned, so what is checked is what would be saved. Graphiti also runs them for records the request only links
  # to, such as the crop of a planting, which are left alone.
  before_save do |record|
    next unless written?(record)

    record.owner = context.current_user if record.new_record?
    context.authorize!(record.new_record? ? :create : :update, record)
  end

  before_destroy do |record|
    context.authorize!(:destroy, record) if written?(record)
  end

  def written?(record)
    record.instance_of?(context.send(:resource_class).model)
  end

  # Photos are attached to plantings, gardens and harvests through the polymorphic photo_associations table.
  # This is the `photos` relationship of one of those; filter[photo_id] on that resource is how photos link back.
  def self.photos_of(type)
    column = "#{type.underscore}_id"
    has_many :photos, resource: PhotoResource, foreign_key: column,
                      base_scope: -> { Photo.by_model(type).select("photos.*, photo_associations.photographable_id AS #{column}") }
    filter :photo_id, :integer do
      eq { |scope, ids| scope.joins(:photo_associations).where(photo_associations: { photo_id: ids }) }
    end
  end

  # The other side of photos_of, for PhotoResource: the plantings, gardens or harvests a photo is attached to.
  def self.photographed(type)
    model = type.constantize
    has_many type.underscore.pluralize.to_sym, foreign_key: :photo_id,
                                               base_scope: -> { model.joins(:photo_associations).select("#{model.table_name}.*, photo_associations.photo_id AS photo_id") }
    filter :"#{type.underscore}_id", :integer do
      eq { |scope, ids| scope.by_model(type).where(photo_associations: { photographable_id: ids }) }
    end
  end

  # A column that can be filtered on but isn't in the response.
  def self.filter_only(name, type)
    attribute name, type, readable: false, writable: false
  end
end
