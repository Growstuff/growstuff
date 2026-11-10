# frozen_string_literal: true

module Admin
  module EcocropDataHelper
    # How the dialogs describe a record, so a wrangler can tell which one they are linking: its names, and what kind of
    # plant it is.
    def ecocrop_details(record)
      {
        scientific_name: [record.scientificname, record.auth].compact_blank.join(' '),
        common_names:    record.common_names,
        family:          record.famname.to_s.split(':').last,
        category:        Array(record.cat).join(', '),
        life_form:       Array(record.lifo).join(', ')
      }.compact_blank
    end

    # The labels for those details, for the dialogs' script.
    def ecocrop_detail_labels
      %i(common_names family category life_form).index_with { |key| t("admin.ecocrop_data.details.#{key}") }
    end

    # What the link dialog needs from a row's button: which record it is for, the common names it could copy, and
    # optionally a name to search for, or the crop to skip the search for (offering only the names it lacks).
    def ecocrop_link_data(record, term: nil, crop: nil)
      names = crop ? record.new_common_names_for(crop) : record.common_names
      { bs_toggle: 'modal', bs_target: '#ecocrop-link-modal', ecocrop_link: record.id, ecocrop_name: record.scientificname,
        ecocrop_names: names.to_json, ecocrop_details: ecocrop_details(record).to_json, ecocrop_term: term,
        ecocrop_crop_id: crop&.id, ecocrop_crop_name: crop&.name }.compact
    end

    # What the create-a-crop dialog needs from a row's button.
    def ecocrop_create_data(record)
      { bs_toggle: 'modal', bs_target: '#ecocrop-create-modal', ecocrop_create: record.id,
        ecocrop_name: record.scientificname, ecocrop_names: record.common_names.to_json,
        ecocrop_details: ecocrop_details(record).to_json }
    end

    # A common name that opens the link dialog already searching for that name.
    def link_name_button(record, name)
      button_tag(type: 'button', class: 'btn btn-outline-secondary btn-sm', data: ecocrop_link_data(record, term: name)) do
        safe_join([icon('fas', 'link'), name], ' ')
      end
    end
  end
end
