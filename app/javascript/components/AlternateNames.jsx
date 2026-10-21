import React from 'react';

import NameFields from './NameFields';

// The alternate names on the crop form: plain text fields.
export default function AlternateNames({names}) {
  return (
    <NameFields
      names={names}
      field="alt_name"
      noun="Alternate name"
      buttonClass="altname"
      help="Alternate name of crop."
      renderInput={({id, name, value, onChange}) => (
        <input type="text" className="form-control" id={id} name={name} value={value} onChange={(event) => onChange(event.target.value)} />
      )}
    />
  );
}
