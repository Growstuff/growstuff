import React, {useState} from 'react';

import PickerButton from './PickerButton';
import PlantSomethingModal from './PlantSomethingModal';

// A button that opens the plant-something dialog for the member's nursery, for
// the panel on their gardens page. Once planted the page reloads to show it.
export default function NurseryPlanter({garden, label, buttonClass}) {
  const [open, setOpen] = useState(false);

  return (
    <>
      <PickerButton label={label} className={buttonClass} onClick={() => setOpen(true)} />
      {open && <PlantSomethingModal garden={garden} onClose={() => setOpen(false)} onCreated={() => window.location.reload()} />}
    </>
  );
}
