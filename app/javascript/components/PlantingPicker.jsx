import React, {useState} from 'react';

import CropPicker from './CropPicker';
import Modal from './Modal';
import PickerButton from './PickerButton';
import RecordHarvestModal from './RecordHarvestModal';
import SaveSeedsModal from './SaveSeedsModal';

// What can be done to a planting from a page that is not about one planting,
// like the home page: the question to ask, and the dialog that does it.
const BIG_TILES = 12; // up to this many plantings get big tiles, more get small ones

const ACTIONS = {
  harvest: {title: 'What did you harvest?', hint: 'These are your plantings. Choose the one you harvested from, or Something else for anything not listed.', elseTitle: 'What else did you harvest?', Dialog: RecordHarvestModal},
  seeds: {title: 'Which plant are you saving seeds from?', hint: 'Only choose a planting if the seeds came from that plant. If you bought tomato seeds from a shop, don\u2019t pick your tomato planting. Choose Something else.', elseTitle: 'Which seeds are you adding?', Dialog: SaveSeedsModal},
};

// A button that asks which of your plantings you mean, then opens the usual
// dialog for that planting (recording a harvest, or saving seeds); once saved
// the page reloads.
//
// plantings: [{id, url, planted_at, ready, thumbnail, garden, crop: {name}}], what is growing, with
// what is ready to pick first.
export default function PlantingPicker({action, label, sublabel, buttonClass, plantings}) {
  const [open, setOpen] = useState(false);
  const [planting, setPlanting] = useState(null);
  const [somethingElse, setElse] = useState(false); // a crop that is not one of the plantings
  const [crop, setCrop] = useState(null); // the crop chosen for seeds, with no planting
  const {title, hint, elseTitle, Dialog} = ACTIONS[action];

  function close() {
    setOpen(false);
    setPlanting(null);
    setElse(false);
    setCrop(null);
  }

  return (
    <>
      <PickerButton label={label} sublabel={sublabel} className={buttonClass} onClick={() => setOpen(true)} />
      {open && !planting && !somethingElse && !crop && (
        <Modal title={title} titleId={`${action}-picker-title`} onClose={close}>
          <div className="modal-body">
            {plantings.length === 0 && <p>You have nothing growing yet.</p>}
            {plantings.length > 0 && <p>{hint}</p>}
            <fieldset className={`planting-tiles${plantings.length > BIG_TILES ? ' planting-tiles-small' : ''}`}>
              <legend className="visually-hidden">Your plantings</legend>
              <button type="button" className="planting-tile planting-tile-other" onClick={() => setElse(true)}>
                <i className="fas fa-plus planting-tile-photo" aria-hidden="true" />
                <span className="planting-tile-name">Something else</span>
              </button>
              {plantings.map((candidate) => (
                <button
                  key={candidate.id}
                  type="button"
                  className="planting-tile"
                  onClick={() => setPlanting(candidate)}
                >
                  {candidate.thumbnail && <img src={candidate.thumbnail} alt="" className="planting-tile-photo" />}
                  <span className="planting-tile-name">{candidate.crop.name}</span>
                  {candidate.garden && <span className="planting-tile-garden">{candidate.garden}</span>}
                  {candidate.ready && <span className="badge text-bg-success">ready</span>}
                </button>
              ))}
            </fieldset>
          </div>
          <div className="modal-footer">
            <button type="button" className="btn btn-link" onClick={close}>Cancel</button>
          </div>
        </Modal>
      )}
      {open && somethingElse && !crop && (
        <Modal title={elseTitle} titleId={`${action}-else-title`} onClose={close}>
          <div className="modal-body">
            <CropPicker
              id={`${action}-else-crop`}
              label="Which crop?"
              placeholder="Start typing a crop name"
              onChoose={(chosen) => {
                if (action === 'harvest') window.location.assign(`/harvests/new?harvest[crop_id]=${chosen.id}`);
                else setCrop(chosen);
              }}
            />
          </div>
          <div className="modal-footer">
            <button type="button" className="btn btn-link" onClick={() => setElse(false)}>Back</button>
          </div>
        </Modal>
      )}
      {open && crop && <SaveSeedsModal crop={crop} onClose={close} onSaved={() => window.location.reload()} />}
      {open && planting && (
        <Dialog planting={planting} onClose={close} onSaved={() => window.location.reload()} />
      )}
    </>
  );
}
