import React, {useState} from 'react';

import {postJson} from '../api';
import {daysBefore, localToday} from '../dates';
import {errorMessages} from '../errors';
import Modal from './Modal';
import WhenPicker from './WhenPicker';

// Transplanting a batch of seedlings out of the nursery: which garden they went
// into, when, and how many. A partial batch leaves the rest in the nursery.
export default function TransplantModal({planting, gardens, onClose, onDone}) {
  const today = localToday();
  const [gardenId, setGardenId] = useState(gardens.length > 0 ? String(gardens[0].id) : '');
  const [when, setWhen] = useState('today');
  const [customDate, setCustomDate] = useState('');
  const [saving, setSaving] = useState(false);
  const [errors, setErrors] = useState([]);
  const [quantity, setQuantity] = useState(String(planting.quantity || ''));
  const asksQuantity = planting.quantity > 1;
  const validQuantity = !asksQuantity || (/^[1-9]\d*$/.test(quantity) && Number(quantity) <= planting.quantity);

  const movedOn = {today, yesterday: daysBefore(today, 1), other: customDate}[when];

  async function save() {
    setSaving(true);
    setErrors([]);
    try {
      const body = {garden_id: gardenId, date: movedOn};
      if (asksQuantity) body.quantity = quantity;
      const {ok, status, data} = await postJson(`/plantings/${planting.slug}/transplant.json`, body);
      if (ok) {
        await onDone(data); // keeps saying so until the page shows it
        return;
      }
      setErrors(errorMessages(status, data, {forbidden: 'You can\'t transplant into that garden.'}));
    } catch (error) {
      setErrors(['Couldn\'t reach the server. Please try again.']);
    }
    setSaving(false);
  }

  return (
    <Modal title={`Transplant ${planting.crop.name}`} titleId={`transplant-title-${planting.id}`} onClose={onClose}>
      <div className="modal-body plant-dialog-body">
        {errors.length > 0 && (
          <div className="alert alert-danger" role="alert">
            <strong>That didn&rsquo;t work.</strong>
            <ul className="mb-0">{errors.map((message) => <li key={message}>{message}</li>)}</ul>
          </div>
        )}
        <fieldset>
          {asksQuantity && (
            <div className="mb-3">
              <label htmlFor={`transplant-quantity-${planting.id}`} className="form-label">{planting.transplant_quantity_label}</label>
              <input id={`transplant-quantity-${planting.id}`} type="number" className="form-control" min="1" max={planting.quantity} required value={quantity} onChange={(event) => setQuantity(event.target.value)} />
            </div>
          )}
          <legend className="crop-picker-label step-legend">Which garden did they go into?</legend>
          {gardens.length > 0 ? (
            <div className="list-group">
              {gardens.map((g) => (
                <label key={g.id} className="list-group-item list-group-item-action">
                  <input
                    type="radio"
                    className="form-check-input me-2"
                    name="transplant-garden"
                    checked={gardenId === String(g.id)}
                    onChange={() => setGardenId(String(g.id))}
                  />
                  {g.name}
                </label>
              ))}
            </div>
          ) : <p className="text-muted">You don&rsquo;t have another garden to transplant into.</p>}
        </fieldset>
        <div className="mt-4">
          <WhenPicker
            id={`transplant-${planting.id}`}
            legend="When?"
            when={when}
            onWhen={(choice) => { setWhen(choice); if (choice === 'other' && !customDate) setCustomDate(today); }}
            date={customDate}
            onDate={(event) => setCustomDate(event.target.value)}
            max={today}
            hint={movedOn}
          />
        </div>
        <div className="visually-hidden" role="status">{saving ? 'Transplanting…' : ''}</div>
      </div>
      <div className="modal-footer">
        <button type="button" className="btn btn-link" onClick={onClose} disabled={saving}>Cancel</button>
        <button
          type="button"
          className="btn btn-success"
          onClick={save}
          disabled={saving || !gardenId || !movedOn || movedOn > today || !validQuantity}
          aria-busy={saving}
        >
          {saving ? <><i className="fas fa-spinner fa-spin" aria-hidden="true" /> Transplanting…</> : 'Transplant'}
        </button>
      </div>
    </Modal>
  );
}
