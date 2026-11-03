# frozen_string_literal: true

module VersionsHelper
  # Changeset fields holding the id of another record, and the model they point at.
  REFERENCE_FIELDS = {
    'creator_id'   => Member,
    'requester_id' => Member,
    'parent_id'    => Crop
  }.freeze

  # Loads, in one query per model, the records a set of versions refers to.
  def self.preload_records(versions)
    ids = Hash.new { |hash, klass| hash[klass] = [] }
    versions.each do |version|
      version.changeset.each { |field, values| ids[REFERENCE_FIELDS[field]].concat(values) if REFERENCE_FIELDS.key?(field) }
    end
    ids.to_h { |klass, values| [klass, klass.where(id: values.compact.uniq).index_by(&:id)] }
  end

  # A changeset value; fields that hold an id are shown as a link to the record they point at.
  # Uses @version_records when the controller preloaded them.
  def version_change_value(field, value)
    return content_tag(:em, '(blank)') if value.blank?

    klass = REFERENCE_FIELDS[field]
    record = version_record(klass, value) if klass
    content_tag(:em, record ? link_to(version_record_name(record), record) : value)
  end

  private

  def version_record(klass, id)
    @version_records&.dig(klass, id.to_i) || klass.find_by(id:)
  end

  def version_record_name(record)
    record.is_a?(Member) ? record.login_name : record.name
  end
end
