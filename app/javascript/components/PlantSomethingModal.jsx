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
    planted_at: options.today, planted_from: '', sunniness: '', quantity: '', description: '',
    overall_rating: '', finished: false,
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
            I planted
            <input
              type="number"
              min="1"
              placeholder="N"
              aria-label="Quantity"
              className="madlib-field madlib-quantity"
              value={fields.quantity}
              onChange={set('quantity')}
            />
            <CropPicker id="planting-crop" value={crop} onChange={setCrop} invalid={errors.some((m) => m.startsWith('Crop'))} />
            {fields.quantity !== '1' && <span className="madlib-aside">(s)</span>}
            {' '}on
            <input
              type="date"
              aria-label="Planted date"
              className="madlib-field madlib-date"
              value={fields.planted_at}
              onChange={set('planted_at')}
            />
            from
            <select aria-label="Planted from" className="madlib-field" value={fields.planted_from} onChange={set('planted_from')}>
              <option value="">…</option>
              {options.planted_from.map((value) => <option key={value} value={value}>{value}</option>)}
            </select>
            in
            <select aria-label="Sun or shade" className="madlib-field" value={fields.sunniness} onChange={set('sunniness')}>
              <option value="">…</option>
              {options.sunniness.map((value) => <option key={value} value={value}>{value}</option>)}
            </select>
            .
          </p>

          <div className="mb-3">
            <label htmlFor="planting-description">Tell us more about it</label>
            <textarea id="planting-description" rows="3" className="form-control" value={fields.description} onChange={set('description')} />
          </div>

          <div className="form-check">
            <input id="planting-finished" type="checkbox" className="form-check-input" checked={fields.finished} onChange={set('finished')} />
            <label htmlFor="planting-finished" className="form-check-label">Mark as finished</label>
          </div>
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
