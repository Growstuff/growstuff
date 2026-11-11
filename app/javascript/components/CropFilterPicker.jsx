import React, {useEffect, useRef, useState} from 'react';

import CropPicker from './CropPicker';

// The crop to filter the crop list by, chosen with the crop picker. Once one is chosen it shows as a chip you can remove,
// so it is plain that something was chosen and not just typed, and the hidden field named `name` holds its id. A change
// event goes up from that field when the choice changes, for the form to apply it.
export default function CropFilterPicker({name, label, placeholder, initial = null, removeLabel = 'Remove'}) {
  const [chosen, setChosen] = useState(initial);
  const field = useRef(null);
  const first = useRef(true);

  useEffect(() => {
    if (first.current) {
      first.current = false;
      return;
    }
    if (field.current) field.current.dispatchEvent(new Event('change', {bubbles: true}));
  }, [chosen]);

  return (
    <div className="crop-filter-picker">
      <input ref={field} type="hidden" name={name} value={chosen ? chosen.id : ''} />
      {chosen ? (
        <div>
          <span className="crop-filter-heading">{label}</span>
          <span className="crop-filter-chosen">
            {chosen.name}
            <button type="button" className="crop-filter-chosen-remove" aria-label={`${removeLabel} ${chosen.name}`} onClick={() => setChosen(null)}>
              <i className="fas fa-times" aria-hidden="true" />
            </button>
          </span>
        </div>
      ) : (
        <CropPicker id="crop-filter-picker" label={label} placeholder={placeholder} autoFocus={false} onChoose={setChosen} />
      )}
    </div>
  );
}
