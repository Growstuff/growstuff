class ApprovedValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors[attribute] << (options[:message] || 'must be approved') unless record.crop.try(:approved?)
  end
end
