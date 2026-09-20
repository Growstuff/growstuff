import React, {useState} from 'react';

import {postJson} from '../api';
import CropPicker from './CropPicker';
import Modal from './Modal';

const FIELD_NAMES = {crop: 'Crop', garden: 'Garden', planted_at: 'Planted date', quantity: 'Quantity'};

function humanize(field) {
  return FIELD_NAMES[field] || field.replace(/_/g, ' ').replace(/^./, (c) => c.toUpperCase());
}

function errorMessages(status, data) {
  if (status === 422 && data && data.errors) {
    return Object.entries(data.errors).flatMap(([field, messages]) => messages.map((m) => `${humanize(field)} ${m}`));
  }
  if (status === 403) return ['You can\'t plant in this garden.'];
  if (status === 401) return ['Please sign in again to plant something.'];
  return ['Something went wrong saving that. Please try again.'];
}

// "Plant something here", as a dialog over the garden cards. The garden is the
// card's, so it isn't asked. On success it hands back the garden's updated card.
export default function PlantSomethingModal({garden, options, onClose, onCreated}) {
  const [crop, setCrop] = useState(null);
  const [fields, setFields] = useState({
    planted_at: options.today, planted_from: '', sunniness: '', quantity: '',
  });
  const [errors, setErrors] = useState([]);
  const [saving, setSaving] = useState(false);

  const set = (name) => (event) => {
    const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    setFields({...fields, [name]: value});
  };

  async function submit(event) {
    event.preventDefault();
    setSaving(true);
    setErrors([]);
    try {
      const {ok, status, data} = await postJson('/plantings.json', {
        planting: {garden_id: garden.id, crop_id: crop ? crop.id : undefined, ...fields},
      });
      if (ok) {
        onCreated(data.garden, crop);
      } else {
        setErrors(errorMessages(status, data));
      }
    } catch (error) {
      setErrors(['Couldn\'t reach the server. Please try again.']);
    } finally {
      setSaving(false);
    }
  }

  const titleId = `plant-something-title-${garden.id}`;

  return (
    <Modal title={`Plant something in ${garden.name}`} titleId={titleId} onClose={onClose}>
      <form onSubmit={submit} noValidate>
        <div className="modal-body">
          {errors.length > 0 && (
            <div className="alert alert-danger" role="alert">
              <ul className="mb-0">{errors.map((message) => <li key={message}>{message}</li>)}</ul>
            </div>
          )}

          <p className="madlib">
            <span className="madlib-phrase">
              I planted
              <input
                type="number"
                min="1"
                placeholder="number"
                aria-label="Quantity"
                className="madlib-field madlib-quantity"
                value={fields.quantity}
                onChange={set('quantity')}
              />
              <CropPicker
                id="planting-crop"
                value={crop}
                onChange={setCrop}
                invalid={errors.some((m) => m.startsWith('Crop'))}
                nextFocusId="planting-planted-at"
              />
              {fields.quantity !== '1' && <span className="madlib-aside">(s)</span>}
            </span>
            {' '}
            <span className="madlib-phrase">
              on
              <input
                id="planting-planted-at"
                type="date"
                aria-label="Planted date"
                className="madlib-field madlib-date"
                value={fields.planted_at}
                onChange={set('planted_at')}
              />
            </span>
            {' '}
            <span className="madlib-phrase">
              from
              <select
                aria-label="Planted from"
                className={`madlib-field${fields.planted_from ? '' : ' madlib-empty'}`}
                value={fields.planted_from}
                onChange={set('planted_from')}
              >
                <option value="">optional</option>
                {options.planted_from.map((value) => <option key={value} value={value}>{value}</option>)}
              </select>
            </span>
            {' '}
            <span className="madlib-phrase">
              in
              <select
                aria-label="Sun or shade"
                className={`madlib-field${fields.sunniness ? '' : ' madlib-empty'}`}
                value={fields.sunniness}
                onChange={set('sunniness')}
              >
                <option value="">optional</option>
                {options.sunniness.map((value) => <option key={value} value={value}>{value}</option>)}
              </select>
              .
            </span>
          </p>
        </div>
        <div className="modal-footer">
          <button type="button" className="btn btn-secondary" onClick={onClose}>Cancel</button>
          <button type="submit" className="btn btn-primary" disabled={saving} aria-busy={saving}>
            {saving ? 'Saving…' : 'Save'}
          </button>
        </div>
      </form>
    </Modal>
  );
}
