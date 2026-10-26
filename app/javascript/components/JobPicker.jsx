import React, {useState} from 'react';

import AddJobModal from './AddJobModal';
import PickerButton from './PickerButton';

// A button that opens the add job dialog. Once saved the page reloads, so it
// shows the new job.
export default function JobPicker({label, sublabel, buttonClass, gardens}) {
  const [open, setOpen] = useState(false);

  return (
    <>
      <PickerButton label={label} sublabel={sublabel} className={buttonClass} onClick={() => setOpen(true)} />
      {open && <AddJobModal gardens={gardens} onClose={() => setOpen(false)} onSaved={() => window.location.reload()} />}
    </>
  );
}
