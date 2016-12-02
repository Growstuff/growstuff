module Growstuff
  module Constants
    class PhotoModels
      PLANTING = { type: 'planting', class: 'Planting', relation: 'plantings' }.freeze
      HARVEST = { type: 'harvest', class: 'Harvest', relation: 'harvests' }.freeze
      GARDEN = { type: 'garden', class: 'Garden', relation: 'gardens' }.freeze

      ALL = [PLANTING, HARVEST, GARDEN].freeze

      def self.types
        ALL.map do |model|
          model[:type]
        end
      end

      def self.relations
        ALL.map do |model|
          model[:relation]
        end
      end

      def self.get_relation(object, type)
        relation = ALL.select do |model|
          model[:type] == type
        end[0][:relation]
        object.send(relation)
      end

      def self.get_item(type)
        class_name = ALL.select do |model|
          model[:type] == type
        end[0][:class]
        class_name.constantize
      end
    end
  end
end
