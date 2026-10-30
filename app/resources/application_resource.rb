# frozen_string_literal: true

class ApplicationResource < Graphiti::Resource
  self.abstract_class = true
  self.adapter = Graphiti::Adapters::ActiveRecord
  self.base_url = Rails.configuration.x.api_base_url
  self.endpoint_namespace = '/api/v1'
  self.default_page_size = 10
  self.max_page_size = 100

  # Pages need an order to be pages of the same list.
  self.default_sort = [{ id: :asc }]

  # The adapter pages with Kaminari, which this app doesn't use.
  paginate do |scope, current_page, per_page, _context, offset|
    scope.limit(per_page).offset(offset.to_i + ((current_page - 1) * per_page))
  end

  # Writes belong to the member holding the token, and are theirs to make. The hooks run once the attributes are
  # assigned, so what is checked is what would be saved. Graphiti also runs them for records the request only links
  # to, such as the crop of a planting, which are left alone.
  before_save do |record|
    next unless written?(record)

    record.owner = context.current_user if record.new_record?
    linked_records_exist!(record)
    context.authorize!(record.new_record? ? :create : :update, record)
  end

  before_destroy do |record|
    context.authorize!(:destroy, record) if written?(record)
  end

  # Photos are attached to plantings, gardens and harvests through the polymorphic photo_associations table.
  # This is the `photos` relationship of one of those; filter[photo_id] on that resource is how photos link back.
  def self.photos_of(type)
    column = "#{type.underscore}_id"
    has_many :photos, resource: PhotoResource, foreign_key: column,
                      base_scope: -> { Photo.by_model(type).select("photos.*, photo_associations.photographable_id AS #{column}") }
    filter :photo_id, :integer do
      eq do |scope, ids|
        scope.where(id: PhotoAssociation.where(photographable_type: type, photo_id: ids).select(:photographable_id))
      end
    end
  end

  # The other side of photos_of, for PhotoResource: the plantings, gardens or harvests a photo is attached to.
  def self.photographed(type)
    model = type.constantize
    has_many type.underscore.pluralize.to_sym, foreign_key: :photo_id,
                                               base_scope:  lambda {
                                                 model.joins(:photo_associations)
                                                   .select("#{model.table_name}.*, photo_associations.photo_id AS photo_id")
                                               }
    filter :"#{type.underscore}_id", :integer do
      eq do |scope, ids|
        scope.where(id: PhotoAssociation.where(photographable_type: type, photographable_id: ids).select(:photo_id))
      end
    end
  end

  # Worked out by the model, so not something the database can filter or sort by.
  def self.computed_attribute(name, type, &)
    attribute(name, type, writable: false, filterable: false, sortable: false, &)
  end

  # Records are put into a garden by someone who can change that garden, as on the website. Being a collaborator
  # is not enough, and the model's own checks do not ask, so a garden that is only linked to has to be authorised.
  def self.needs_writable_garden
    before_save do |record|
      context.authorize!(:update, record.garden) if written?(record) && record.garden && record.garden_id_changed?
    end
  end

  # A column that can be filtered on but isn't in the response.
  def self.filter_only(name, type)
    attribute name, type, readable: false, writable: false
  end

  # Read only: it can be listed and shown, and nothing else.
  def self.read_only
    primary_endpoint "/#{type}", %i(index show)
  end

  # The member a record belongs to. It is the member holding the token that wrote it, so it is never set by a request.
  def self.owned
    filter_only :owner_id, :integer
    belongs_to :owner, resource: MemberResource
  end

  private

  def written?(record)
    record.instance_of?(context.resource_class.model)
  end

  # A foreign key that points at nothing is a request for something that is not there, not a server error.
  def linked_records_exist!(record)
    record.class.reflect_on_all_associations(:belongs_to).reject(&:polymorphic?).each do |association|
      next if record[association.foreign_key].blank? || record.association(association.name).reader

      raise ActiveRecord::RecordNotFound, "Couldn't find #{association.klass.name} with id #{record[association.foreign_key]}"
    end
  end
end
