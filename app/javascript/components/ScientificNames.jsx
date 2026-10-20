import React from 'react';

import GbifNameInput from './GbifNameInput';
import NameFields from './NameFields';

// The scientific names on the crop form: text fields that suggest names from
// GBIF. `suggest_url` is where those suggestions come from.
export default function ScientificNames({names, suggest_url: suggestUrl}) {
  return (
    <NameFields
      names={names}
      field="sci_name"
      noun="Scientific name"
      buttonClass="sciname"
      help="Searches GBIF to determine scientific name of crop."
      renderInput={(props) => <GbifNameInput {...props} url={suggestUrl} />}
    />
  );
}
