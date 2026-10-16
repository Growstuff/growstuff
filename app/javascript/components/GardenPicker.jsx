import React, {useState} from 'react';

import GardenFormModal from './GardenFormModal';
import PickerButton from './PickerButton';

// A button that opens the new-garden dialog, for pages that are not a list of
// garden cards, like the home page. Once saved the page reloads, so it shows
// the new garden.
export default function GardenPicker({label, buttonClass}) {
  const [open, setOpen] = useState(false);

  return (
    <>
      <PickerButton label={label} className={buttonClass} onClick={() => setOpen(true)} />
      {open && <GardenFormModal onClose={() => setOpen(false)} onSaved={() => window.location.reload()} />}
    </>
  );
}
