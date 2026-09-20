import React, {useEffect, useRef, useState} from 'react';

import {postJson} from '../api';
import CropPicker from './CropPicker';
import Modal from './Modal';

const FIELD_NAMES = {crop: 'Crop', garden: 'Garden'};
const STEPS = ['Choose a crop', 'Confirm'];

function humanize(field) {
  return FIELD_NAMES[field] || field.replace(/_/g, ' ').replace(/^./, (c) => c.toUpperCase());
}

function errorMessages(status, data) {
  if (status === 422 && data && data.errors) {
    const messages = Object.entries(data.errors).flatMap(([field, list]) => list.map((m) => `${humanize(field)} ${m}`));
    if (messages.length > 0) return messages;
  }
  if (status === 403) return ['You can\'t plant in this garden.'];
  if (status === 401) return ['Please sign in again to plant something.'];
  return ['Something went wrong saving that. Please try again.'];
}

// Where you are: done steps get a tick, the current one is marked for
// assistive technology as well as by colour.
function Steps({current}) {
  return (
    <ol className="plant-steps" aria-label="Progress">
      {STEPS.map((label, index) => {
        const number = index + 1;
        const state = number < current ? 'done' : number === current ? 'current' : 'todo';
        return (
          <li key={label} className={`plant-step plant-step-${state}`} aria-current={state === 'current' ? 'step' : undefined}>
            <span className="plant-step-number">
              {state === 'done' ? <i className="fa fa-check" aria-hidden="true" /> : number}
            </span>
            {label}
            {state === 'done' && <span className="visually-hidden"> (done)</span>}
          </li>
        );
      })}
    </ol>
  );
}

// "Add planting", as a dialog over the garden cards. Two steps: search
// for a crop and choose it, then confirm what you chose and it is planted in the
// card's garden (today, with no other details; those can be added later). On
// success it hands back the garden's updated card.
export default function PlantSomethingModal({garden, iconUrl, onClose, onCreated}) {
  const [crop, setCrop] = useState(null); // chosen, waiting for confirmation
  const [saving, setSaving] = useState(false);
  const [errors, setErrors] = useState([]);
  const confirmButton = useRef(null);

  // Once a crop is chosen the search goes away; Enter then confirms.
  useEffect(() => {
    if (crop && confirmButton.current) confirmButton.current.focus();
  }, [crop]);

  async function confirm() {
    setSaving(true);
    setErrors([]);
    try {
      const {ok, status, data} = await postJson('/plantings.json', {planting: {garden_id: garden.id, crop_id: crop.id}});
      if (ok) {
        onCreated(data.garden, crop); // closes this dialog
        return;
      }
      setErrors(errorMessages(status, data));
    } catch (error) {
      setErrors(['Couldn\'t reach the server. Please try again.']);
    }
    setSaving(false);
  }

  const title = (
    <>
      {iconUrl && <img src={iconUrl} alt="" className="modal-title-icon" />}
      Plant something in {garden.name}
    </>
  );

  return (
    <Modal title={title} titleId={`plant-something-title-${garden.id}`} onClose={onClose}>
      <div className="modal-body plant-dialog-body">
        <Steps current={crop ? 2 : 1} />
        {errors.length > 0 && (
          <div className="alert alert-danger" role="alert">
            <i className="fa fa-exclamation-triangle" aria-hidden="true" />{' '}
            <strong>That didn&rsquo;t work.</strong>
            <ul className="mb-0">{errors.map((message) => <li key={message}>{message}</li>)}</ul>
            <span>Your choice is kept, so you can press Plant it to try again.</span>
          </div>
        )}
        {crop ? (
          <div className="crop-confirm">
            <p className="crop-confirm-label">Ready to plant?</p>
            <dl className="crop-confirm-details">
              <dt>Crop</dt>
              <dd className="crop-confirm-name">
                {crop.name}
                <button type="button" className="btn btn-sm btn-outline-secondary" onClick={() => setCrop(null)} disabled={saving}>
                  <i className="fa fa-edit" aria-hidden="true" /> Change<span className="visually-hidden"> crop</span>
                </button>
              </dd>
              <dt>Garden</dt>
              <dd>{garden.name}</dd>
              <dt>When</dt>
              <dd>Today</dd>
            </dl>
          </div>
        ) : (
          <CropPicker id="planting-crop" onChoose={setCrop} />
        )}
        <div className="visually-hidden" role="status">{saving ? `Planting ${crop.name} in ${garden.name}…` : ''}</div>
      </div>
      <div className="modal-footer">
        <button type="button" className="btn btn-link" onClick={onClose} disabled={saving}>Cancel</button>
        {crop && (
          <button ref={confirmButton} type="button" className="btn btn-success btn-plant" onClick={confirm} disabled={saving} aria-busy={saving}>
            {saving ? <><i className="fa fa-spinner fa-spin" aria-hidden="true" /> Planting…</> : 'Plant it'}
          </button>
        )}
      </div>
    </Modal>
  );
}
