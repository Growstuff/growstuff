import React, {useState} from 'react';

import CropPicker from './CropPicker';
import Modal from './Modal';
import PickerButton from './PickerButton';
import Steps from './Steps';
import RecordHarvestModal from './RecordHarvestModal';
import SaveSeedsModal from './SaveSeedsModal';

// What can be done to a planting from a page that is not about one planting,
// like the home page: the question to ask, and the dialog that does it.
const BIG_TILES = 12; // up to this many plantings get big tiles, more get small ones

// Where seeds that were not saved from one of your plants can have come from;
// the keys are SaveSeedsModal's SOURCES.
const SOURCE_TILES = [
  {key: 'bought', icon: 'shopping-basket', name: 'Seeds I bought'},
  {key: 'catalogue', icon: 'book-open', name: 'Ordered from a seed catalogue'},
  {key: 'seedbank', icon: 'landmark', name: 'From a seed bank or library'},
  {key: 'traded', icon: 'exchange-alt', name: 'Traded with someone'},
  {key: 'other', icon: 'question', name: 'Somewhere else, or not sure'},
];

const ACTIONS = {
  harvest: {title: 'What did you harvest?', hint: 'These are your plantings. Choose the one you harvested from, or Something else for anything not listed.', elseTitle: 'What else did you harvest?', Dialog: RecordHarvestModal},
  seeds: {title: 'Which plant are you saving seeds from?', hint: 'Choose the plant you saved the seeds from.', elseTitle: 'Which seeds are you adding?', Dialog: SaveSeedsModal},
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
  const [fromPlanting, setFromPlanting] = useState(false); // seeds: yes, they were saved from one of the plantings
  const [source, setSource] = useState(null); // seeds: where the ones that were not saved from a plant came from
  const [crop, setCrop] = useState(null); // the crop chosen for seeds, with no planting
  const {title, hint, elseTitle, Dialog} = ACTIONS[action];

  function close() {
    setOpen(false);
    setPlanting(null);
    setElse(false);
    setCrop(null);
    setSource(null);
    setFromPlanting(false);
  }

  // The steps before the dialog's own, so the progress shows the whole way through.
  const choose = somethingElse ? 'Which crop?' : 'Which plant?';
  const lead = action === 'seeds' ? ['Where from?', choose] : [choose];
  const stepsBefore = (current) => <Steps steps={[...lead, ...(Dialog.STEPS || [])]} current={current} />;
  const askingSource = action === 'seeds' && !fromPlanting && !somethingElse; // seeds start with: from a plant of yours?

  return (
    <>
      <PickerButton label={label} sublabel={sublabel} className={buttonClass} onClick={() => setOpen(true)} />
      {open && askingSource && !planting && !crop && (
        <Modal title="Where did these seeds come from?" titleId="seeds-source-title" onClose={close}>
          <div className="modal-body">
            {stepsBefore(1)}
            <div className="planting-tiles">
              <button type="button" className="planting-tile" onClick={() => setFromPlanting(true)}>
                <i className="fas fa-seedling planting-tile-photo" aria-hidden="true" />
                <span className="planting-tile-name">Seeds I saved from my plants</span>
              </button>
              {SOURCE_TILES.map(({key, icon, name}) => (
                <button key={key} type="button" className="planting-tile" onClick={() => { setSource(key); setElse(true); }}>
                  <i className={`fas fa-${icon} planting-tile-photo`} aria-hidden="true" />
                  <span className="planting-tile-name">{name}</span>
                </button>
              ))}
            </div>
          </div>
          <div className="modal-footer">
            <button type="button" className="btn btn-link" onClick={close}>Cancel</button>
          </div>
        </Modal>
      )}
      {open && !askingSource && !planting && !somethingElse && !crop && (
        <Modal title={title} titleId={`${action}-picker-title`} onClose={close}>
          <div className="modal-body">
            {stepsBefore(lead.length)}
            {plantings.length === 0 && <p>You have nothing growing yet.</p>}
            {plantings.length > 0 && <p>{hint}</p>}
            <fieldset className={`planting-tiles${plantings.length > BIG_TILES ? ' planting-tiles-small' : ''}`}>
              <legend className="visually-hidden">Your plantings</legend>
              {action === 'harvest' && (
                <button type="button" className="planting-tile planting-tile-other" onClick={() => setElse(true)}>
                  <i className="fas fa-plus planting-tile-photo" aria-hidden="true" />
                  <span className="planting-tile-name">Something else</span>
                </button>
              )}
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
            {action === 'seeds' && <button type="button" className="btn btn-link" onClick={() => setFromPlanting(false)}>Back</button>}
            <button type="button" className="btn btn-link" onClick={close}>Cancel</button>
          </div>
        </Modal>
      )}
      {open && somethingElse && !crop && (
        <Modal title={elseTitle} titleId={`${action}-else-title`} onClose={close}>
          <div className="modal-body">
            {stepsBefore(lead.length)}
            <CropPicker
              id={`${action}-else-crop`}
              label="Which crop?"
              placeholder="Start typing a crop name"
              onChoose={(chosen) => {
                setCrop(chosen);
              }}
            />
          </div>
          <div className="modal-footer">
            <button type="button" className="btn btn-link" onClick={() => { setElse(false); setSource(null); }}>Back</button>
          </div>
        </Modal>
      )}
      {open && crop && <Dialog crop={crop} source={action === 'seeds' ? source : undefined} lead={lead} onBack={() => setCrop(null)} onClose={close} onSaved={() => window.location.reload()} />}
      {open && planting && (
        <Dialog planting={planting} lead={lead} onBack={() => setPlanting(null)} onClose={close} onSaved={() => window.location.reload()} />
      )}
    </>
  );
}
