import React, {useState} from 'react';

import PickerButton from './PickerButton';
import SowSeedsModal from './SowSeedsModal';

// A button that opens the sow-seeds dialog for a member who has not planted
// anything yet, in the notice that follows them round the site. They have no
// nursery, so what they sow goes into one of their gardens. Once it is saved the
// page reloads, which takes the notice away.
export default function FirstStepsPlanter({gardens, seeds, label, buttonClass}) {
  const [open, setOpen] = useState(false);

  return (
    <>
      <PickerButton label={label} className={buttonClass} onClick={() => setOpen(true)} />
      {open && (
        <SowSeedsModal
          nursery={null}
          gardens={gardens}
          seeds={seeds}
          onClose={() => setOpen(false)}
          onSown={() => window.location.reload()}
        />
      )}
    </>
  );
}
