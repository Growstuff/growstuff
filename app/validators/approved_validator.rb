class ApprovedValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value.approved?
      record.errors[attribute] << (options[:message] || 'must be approved')
    end
  end
end
