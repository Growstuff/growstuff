import React, {useState} from 'react';

import PickerButton from './PickerButton';
import PlantingFlow from './PlantingFlow';

// A button that opens PlantingFlow over the plantings it is given.
export default function PlantingPicker({action, label, sublabel, buttonClass, plantings}) {
  const [open, setOpen] = useState(false);

  return (
    <>
      <PickerButton label={label} sublabel={sublabel} className={buttonClass} onClick={() => setOpen(true)} />
      {open && <PlantingFlow action={action} plantings={plantings} onClose={() => setOpen(false)} />}
    </>
  );
}
