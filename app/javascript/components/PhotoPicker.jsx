import React, {useState} from 'react';

import AddPhotoModal from './AddPhotoModal';
import PickerButton from './PickerButton';

// A button that opens the add-photo dialog for one garden, for pages that are
// not a list of garden cards. Once the photo is added the page reloads.
export default function PhotoPicker({label, sublabel, buttonClass, garden, newUrl}) {
  const [open, setOpen] = useState(false);

  return (
    <>
      <PickerButton label={label} sublabel={sublabel} className={buttonClass} onClick={() => setOpen(true)} />
      {open && (
        <AddPhotoModal
          label={garden.name}
          newUrl={newUrl}
          onClose={() => setOpen(false)}
          onAdded={() => window.location.reload()}
        />
      )}
    </>
  );
}
