# frozen_string_literal: true

module Api
  # The API has always spoken dashes, as in `planted-at` and `filter[owner-id]`, while Graphiti works in
  # underscores. This puts the dashes back at the edges: request params go in underscored, and the
  # attribute names in the response come out dasherised.
  module DashedKeys
    extend ActiveSupport::Concern

    included do
      before_action :underscore_request_keys
      after_action :dasherize_response_keys
    end

    private

    def underscore_request_keys
      underscore_filters
      params[:sort] = params[:sort].split(',').map { |field| underscore_field(field) }.join(',') if params[:sort].is_a?(String)
      underscore_fields
      underscore_page_limit
      return unless params.dig(:data, :attributes).respond_to?(:transform_keys)

      params[:data][:attributes] = params[:data][:attributes].transform_keys(&:underscore)
    end

    # filter[crop]=1 has always meant the same as filter[crop_id]=1.
    def underscore_filters
      filters = params[:filter]
      return unless filters.respond_to?(:transform_keys)

      params[:filter] = filters.transform_keys do |name|
        name = name.underscore
        relationship_filter?(name, filters[name]) ? "#{name}_id" : name
      end
    end

    def relationship_filter?(name, value)
      known = resource_class.config[:filters]
      !value.respond_to?(:keys) && !known.key?(name.to_sym) && known.key?(:"#{name}_id")
    end

    def underscore_field(field)
      field.start_with?('-') ? "-#{field.delete_prefix('-').underscore}" : field.underscore
    end

    def underscore_fields
      return unless params[:fields].respond_to?(:transform_values)

      params[:fields] = params[:fields].transform_values { |names| names.to_s.underscore }
    end

    # Graphiti pages by number and size; clients of this API have always paged by `page[limit]` and
    # `page[offset]`. An offset that lands on a page boundary is the same as a page number.
    def underscore_page_limit
      page = params[:page]
      return unless page.respond_to?(:key?) && page.key?(:limit)

      size = page.delete(:limit).to_i
      page[:size] = size
      offset = page[:offset]
      return unless offset.present? && size.positive? && (offset.to_i % size).zero?

      page.delete(:offset)
      page[:number] = (offset.to_i / size) + 1
    end

    def dasherize_response_keys
      return unless response.media_type == Mime[:jsonapi].to_s && response.body.present?

      document = JSON.parse(response.body)
      resources = [document['data'], document['included']].flatten.compact
      resources.each { |resource| dasherize_attributes(resource) }
      Array(document['errors']).each { |error| dasherize_pointer(error) }
      response.body = JSON.generate(document)
    end

    def dasherize_attributes(resource)
      return unless resource.is_a?(Hash) && resource['attributes'].is_a?(Hash)

      resource['attributes'] = resource['attributes'].transform_keys(&:dasherize)
    end

    def dasherize_pointer(error)
      pointer = error.dig('source', 'pointer')
      return unless pointer

      error['source']['pointer'] = pointer.sub(%r{\A/data/attributes/(.+)\z}) { "/data/attributes/#{Regexp.last_match(1).dasherize}" }
    end
  end
end
