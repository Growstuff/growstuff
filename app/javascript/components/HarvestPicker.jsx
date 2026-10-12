import React, {useState} from 'react';

import Modal from './Modal';
import RecordHarvestModal from './RecordHarvestModal';

// A button for recording a harvest from a page that is not about one planting,
// like the home page. It asks which of your plantings you harvested from, then
// opens the usual dialog for that planting; once saved the page reloads.
//
// plantings: [{id, url, planted_at, ready, crop: {name}}], what is growing, with
// what is ready to pick first.
export default function HarvestPicker({label, buttonClass, plantings}) {
  const [open, setOpen] = useState(false);
  const [planting, setPlanting] = useState(null);

  function close() {
    setOpen(false);
    setPlanting(null);
  }

  return (
    <>
      <button type="button" className={buttonClass} onClick={() => setOpen(true)}>{label}</button>
      {open && !planting && (
        <Modal title="What did you harvest?" titleId="harvest-picker-title" onClose={close}>
          <div className="modal-body">
            {plantings.length === 0 ? (
              <p className="mb-0">You have nothing growing to harvest yet. Plant something first.</p>
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
        <RecordHarvestModal planting={planting} onClose={close} onSaved={() => window.location.reload()} />
      )}
    </>
  );
}
