# frozen_string_literal: true

# Saving a garden with a location looks it up on Wikidata, a real HTTPS request
# of about half a second each. Specs don't need the answer, so no lookup is made.
RSpec.configure do |config|
  config.before do
    allow(WikidataService).to receive_messages(find_wikidata_id: nil, fetch_temps: {})
  end
end
