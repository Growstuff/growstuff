import React, {useState} from 'react';

import {showSaved} from '../nurseryPanel';
import PickerButton from './PickerButton';
import SowSeedsModal from './SowSeedsModal';

// A button that opens the sow-seeds dialog for the member's nursery, on their
// gardens page. Once sown, the nursery and the garden show it, without a reload.
export default function NurseryPlanter({garden, gardens, seeds, label, buttonClass}) {
  const [open, setOpen] = useState(false);

  return (
    <>
      <PickerButton label={label} className={buttonClass} onClick={() => setOpen(true)} />
      {open && (
        <SowSeedsModal
          nursery={garden}
          gardens={gardens}
          seeds={seeds}
          onClose={() => setOpen(false)}
          onSown={showSaved}
        />
      )}
    </>
  );
}
