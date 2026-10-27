import React, {useEffect, useRef, useState} from 'react';

import {postJson} from '../api';
import {daysBefore, localToday} from '../dates';
import CropPicker from './CropPicker';
import Modal from './Modal';
import Steps from './Steps';
import WhenPicker from './WhenPicker';

const FIELD_NAMES = {crop: 'Crop', garden: 'Garden'};
const STEPS = ['Choose a crop', 'Confirm'];
const STEPS_WITH_GARDEN = ['Choose a crop', 'Which garden?', 'Confirm'];

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

// "Add planting", as a dialog over the garden cards. Two steps: search
// for a crop and choose it, then confirm what you chose and it is planted in the
// card's garden (today unless you say otherwise, with no other details; those
// can be added later). On success it hands back the garden's updated card.
//
// Pass gardens, more than one, to ask which of them after the crop; the garden
// is then the one chosen. Otherwise it is planted in `garden`.
//
// Pass a crop to start on the confirm step with it already chosen; Change still
// goes back to the search.
export default function PlantSomethingModal({garden: fixedGarden, gardens = [], iconUrl, crop: chosenCrop = null, onClose, onCreated}) {
  const askingGarden = gardens.length > 1;
  const [garden, setGarden] = useState(askingGarden ? null : fixedGarden); // where it goes; null until chosen
  const [crop, setCrop] = useState(chosenCrop); // chosen, waiting for confirmation
  const [when, setWhen] = useState('today'); // today, yesterday, or other (a date you enter)
  const [customDate, setCustomDate] = useState('');
  const [saving, setSaving] = useState(false);
  const [errors, setErrors] = useState([]);
  const confirmButton = useRef(null);

  // Once a crop is chosen the search goes away; Enter then confirms.
  useEffect(() => {
    if (crop && garden && confirmButton.current) confirmButton.current.focus();
  }, [crop, garden]);

  const today = localToday();
  const plantedOn = {today, yesterday: daysBefore(today, 1), other: customDate}[when];

  function chooseWhen(choice) {
    setWhen(choice);
    if (choice === 'other' && !customDate) setCustomDate(today);
  }

  async function confirm() {
    setSaving(true);
    setErrors([]);
    try {
      // Today is left to the server, which knows what day it is where it is.
      const planting = {garden_id: garden.id, crop_id: crop.id, ...(when === 'today' ? {} : {planted_at: plantedOn})};
      const {ok, status, data} = await postJson('/plantings.json', {planting});
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
      Plant something{garden && ` in ${garden.name}`}
    </>
  );

  return (
    <Modal title={title} titleId={`plant-something-title-${garden ? garden.id : 'new'}`} onClose={onClose}>
      <div className="modal-body plant-dialog-body">
        <Steps steps={askingGarden ? STEPS_WITH_GARDEN : STEPS} current={!crop ? 1 : (askingGarden && !garden ? 2 : STEPS.length + (askingGarden ? 1 : 0))} />
        {errors.length > 0 && (
          <div className="alert alert-danger" role="alert">
            <i className="fas fa-exclamation-triangle" aria-hidden="true" />{' '}
            <strong>That didn&rsquo;t work.</strong>
            <ul className="mb-0">{errors.map((message) => <li key={message}>{message}</li>)}</ul>
            <span>Your choice is kept, so you can press Plant it to try again.</span>
          </div>
        )}
        {crop && !garden && (
          <fieldset>
            <legend className="crop-picker-label step-legend">Which garden is it going in?</legend>
            <div className="pill-choices">
              {gardens.map((choice) => (
                <button key={choice.id} type="button" className="pill-choice" onClick={() => setGarden(choice)}>{choice.name}</button>
              ))}
            </div>
          </fieldset>
        )}
        {crop && garden && (
          <div className="crop-confirm">
            <p className="crop-confirm-label">Ready to plant?</p>
            <dl className="crop-confirm-details">
              <dt>Crop</dt>
              <dd className="crop-confirm-name">
                {crop.name}
                <button type="button" className="btn btn-sm btn-outline-secondary" onClick={() => setCrop(null)} disabled={saving}>
                  <i className="fas fa-edit" aria-hidden="true" /> Change<span className="visually-hidden"> crop</span>
                </button>
              </dd>
              <dt>Garden</dt>
              <dd>
                {garden.name}
                {askingGarden && (
                  <button type="button" className="btn btn-sm btn-outline-secondary" onClick={() => setGarden(null)} disabled={saving}>
                    <i className="fas fa-edit" aria-hidden="true" /> Change<span className="visually-hidden"> garden</span>
                  </button>
                )}
              </dd>
            </dl>
            <WhenPicker
              id="plant-something"
              legend="When did you plant it?"
              when={when}
              onWhen={chooseWhen}
              date={customDate}
              onDate={(event) => setCustomDate(event.target.value)}
              hint={plantedOn}
            />
          </div>
        )}
        {!crop && <CropPicker id="planting-crop" onChoose={setCrop} />}
        <div className="visually-hidden" role="status">{saving ? `Planting ${crop.name} in ${garden.name}…` : ''}</div>
      </div>
      <div className="modal-footer">
        <button type="button" className="btn btn-link" onClick={onClose} disabled={saving}>Cancel</button>
        {crop && garden && (
          <button ref={confirmButton} type="button" className="btn btn-success btn-plant" onClick={confirm} disabled={saving} aria-busy={saving}>
            {saving ? <><i className="fas fa-spinner fa-spin" aria-hidden="true" /> Planting…</> : 'Plant it'}
          </button>
        )}
      </div>
    </Modal>
  );
}
