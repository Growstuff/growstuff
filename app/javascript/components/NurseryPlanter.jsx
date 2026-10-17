import React, {useState} from 'react';

import PickerButton from './PickerButton';
import SowSeedsModal from './SowSeedsModal';

// A button that opens the sow-seeds dialog for the member's nursery, on their
// gardens page. Once sown the page reloads to show it.
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
          onSown={() => window.location.reload()}
        />
      )}
    </>
  );
}
