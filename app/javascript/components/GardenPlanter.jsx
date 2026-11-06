import React, {useState} from 'react';

import PlantSomethingModal from './PlantSomethingModal';

// The "add" on a garden page's list of plantings: a button that opens the
// plant something dialog for this garden. Once planted the page reloads, so
// the new planting shows in the list.
export default function GardenPlanter({garden, label = 'add', buttonClass, iconUrl}) {
  const [open, setOpen] = useState(false);

  return (
    <>
      <button type="button" className={buttonClass} onClick={() => setOpen(true)}>
        <i className="fas fa-plus" aria-hidden="true" /> {label}
      </button>
      {open && (
        <PlantSomethingModal
          garden={garden}
          iconUrl={iconUrl}
          onClose={() => setOpen(false)}
          onCreated={() => window.location.reload()}
        />
      )}
    </>
  );
}
