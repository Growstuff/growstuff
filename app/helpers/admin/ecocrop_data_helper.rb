# frozen_string_literal: true

module Admin
  module EcocropDataHelper
    # What the link dialog needs from a row's button: which record it is for, and optionally a name to search for.
    def ecocrop_link_data(record, term: nil)
      { bs_toggle: 'modal', bs_target: '#ecocrop-link-modal', ecocrop_link: record.id,
        ecocrop_name: record.scientificname, ecocrop_term: term }.compact
    end

    # A common name that opens the link dialog already searching for that name.
    def link_name_button(record, name)
      button_tag(type: 'button', class: 'btn btn-outline-secondary btn-sm', data: ecocrop_link_data(record, term: name)) do
        safe_join([icon('fas', 'link'), name], ' ')
      end
    end
  end
end
