import React, {useState} from 'react';

import PickerButton from './PickerButton';
import PlantSomethingModal from './PlantSomethingModal';

// A button that opens the "plant something" dialog for one garden, for pages
// that are not a list of garden cards, like the home page's first steps.
// Give it a crop to open with that crop already chosen. Once planted the page
// reloads, so it shows what is now growing.
export default function PlantPicker({label, sublabel, buttonClass, garden, crop}) {
  const [open, setOpen] = useState(false);

  return (
    <>
      <PickerButton label={label} sublabel={sublabel} className={buttonClass} onClick={() => setOpen(true)} />
      {open && (
        <PlantSomethingModal
          garden={garden}
          crop={crop}
          onClose={() => setOpen(false)}
          onCreated={() => window.location.reload()}
        />
      )}
    </>
  );
}
