import React, {useState} from 'react';

import CropPicker from './CropPicker';
import Modal from './Modal';
import PickerButton from './PickerButton';
import SaveSeedsModal from './SaveSeedsModal';

// A button that adds seeds to your seed library, for seeds you bought as much
// as ones you saved: choose the crop, then the usual save seeds dialog. Once
// saved the page reloads.
export default function AddSeedsPicker({label, buttonClass}) {
  const [open, setOpen] = useState(false);
  const [crop, setCrop] = useState(null);

  function close() {
    setOpen(false);
    setCrop(null);
  }

  return (
    <>
      <PickerButton label={label} className={buttonClass} onClick={() => setOpen(true)} />
      {open && !crop && (
        <Modal title="Add seeds" titleId="add-seeds-picker-title" onClose={close}>
          <div className="modal-body">
            <CropPicker id="add-seeds-crop" label="Which seeds?" placeholder="Start typing a crop name" onChoose={setCrop} />
          </div>
          <div className="modal-footer">
            <button type="button" className="btn btn-link" onClick={close}>Cancel</button>
          </div>
        </Modal>
      )}
      {open && crop && <SaveSeedsModal crop={crop} onClose={close} onSaved={() => window.location.reload()} />}
    </>
  );
}
