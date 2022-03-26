# frozen_string_literal: true

class ApprovedValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, _value)
    record.errors[attribute].add(options[:message] || 'must be approved') unless record.crop.try(:approved?)
  end
end
