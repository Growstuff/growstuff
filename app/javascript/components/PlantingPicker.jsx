import React, {useState} from 'react';

import Modal from './Modal';
import PickerButton from './PickerButton';
import RecordHarvestModal from './RecordHarvestModal';
import SaveSeedsModal from './SaveSeedsModal';

// What can be done to a planting from a page that is not about one planting,
// like the home page: the question to ask, and the dialog that does it.
const ACTIONS = {
  harvest: {title: 'What did you harvest?', Dialog: RecordHarvestModal},
  seeds: {title: 'Which plant are you saving seeds from?', Dialog: SaveSeedsModal},
};

// A button that asks which of your plantings you mean, then opens the usual
// dialog for that planting (recording a harvest, or saving seeds); once saved
// the page reloads.
//
// plantings: [{id, url, planted_at, ready, crop: {name}}], what is growing, with
// what is ready to pick first.
export default function PlantingPicker({action, label, sublabel, buttonClass, plantings}) {
  const [open, setOpen] = useState(false);
  const [planting, setPlanting] = useState(null);
  const {title, Dialog} = ACTIONS[action];

  function close() {
    setOpen(false);
    setPlanting(null);
  }

  return (
    <>
      <PickerButton label={label} sublabel={sublabel} className={buttonClass} onClick={() => setOpen(true)} />
      {open && !planting && (
        <Modal title={title} titleId={`${action}-picker-title`} onClose={close}>
          <div className="modal-body">
            {plantings.length === 0 ? (
              <p className="mb-0">You have nothing growing yet. Plant something first.</p>
            ) : (
              <fieldset className="harvest-picker-list">
                <legend className="visually-hidden">Your plantings</legend>
                {plantings.map((candidate) => (
                  <button
                    key={candidate.id}
                    type="button"
                    className="harvest-picker-planting"
                    onClick={() => setPlanting(candidate)}
                  >
                    <span>{candidate.crop.name}</span>
                    {candidate.ready && <span className="badge text-bg-success">ready</span>}
                  </button>
                ))}
              </fieldset>
            )}
          </div>
          <div className="modal-footer">
            <button type="button" className="btn btn-link" onClick={close}>Cancel</button>
          </div>
        </Modal>
      )}
      {open && planting && (
        <Dialog planting={planting} onClose={close} onSaved={() => window.location.reload()} />
      )}
    </>
  );
}
