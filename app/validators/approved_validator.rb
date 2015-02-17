class ApprovedValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless record.crop.try(:approved?)
      record.errors[attribute] << (options[:message] || 'must be approved')
    end
  end
end
