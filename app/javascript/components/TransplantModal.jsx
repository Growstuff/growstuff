import React, {useState} from 'react';

import {postJson} from '../api';
import {daysBefore, localToday} from '../dates';
import Modal from './Modal';
import WhenPicker from './WhenPicker';

function errorMessages(status, data) {
  if (status === 422 && data && data.errors) {
    const messages = Object.values(data.errors).flat();
    if (messages.length > 0) return messages;
  }
  if (status === 403) return ['You can\'t transplant into that garden.'];
  return ['Something went wrong transplanting. Please try again.'];
}

// Transplanting seedlings out of the nursery. First where they went and when,
// then whether that was all of them: if not, how many, and the rest stay in the
// nursery. Nothing is saved until the second question is answered.
export default function TransplantModal({planting, gardens, onClose, onDone}) {
  const total = planting.quantity || 1;
  const today = localToday();
  const [step, setStep] = useState(1);
  const [gardenId, setGardenId] = useState(gardens.length > 0 ? String(gardens[0].id) : '');
  const [when, setWhen] = useState('today');
  const [customDate, setCustomDate] = useState('');
  const [all, setAll] = useState(true);
  const [count, setCount] = useState(Math.max(1, total - 1));
  const [saving, setSaving] = useState(false);
  const [errors, setErrors] = useState([]);

  const movedOn = {today, yesterday: daysBefore(today, 1), other: customDate}[when];
  const garden = gardens.find((g) => String(g.id) === gardenId);
  const name = planting.crop.name;

  async function save() {
    setSaving(true);
    setErrors([]);
    try {
      const body = {garden_id: gardenId, ...(when === 'today' ? {} : {date: movedOn}), ...(all ? {} : {quantity: count})};
      const {ok, status, data} = await postJson(`/plantings/${planting.slug}/transplant.json`, body);
      if (ok) {
        onDone();
        return;
      }
      setErrors(errorMessages(status, data));
    } catch (error) {
      setErrors(['Couldn\'t reach the server. Please try again.']);
    }
    setSaving(false);
  }

  return (
    <Modal title={`Transplant ${name}`} titleId={`transplant-title-${planting.id}`} onClose={onClose}>
      <div className="modal-body plant-dialog-body">
        {errors.length > 0 && (
          <div className="alert alert-danger" role="alert">
            <strong>That didn&rsquo;t work.</strong>
            <ul className="mb-0">{errors.map((message) => <li key={message}>{message}</li>)}</ul>
          </div>
        )}
        {step === 1 ? (
          <>
            <fieldset>
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
          </>
        ) : (
          <fieldset>
            <legend className="crop-picker-label step-legend">Was that all of the {name}?</legend>
            <p className="text-muted">
              {total} {name} {total === 1 ? 'was' : 'were'} in the nursery, and they are going into {garden && garden.name}.
            </p>
            <div className="form-check">
              <input className="form-check-input" type="radio" id="transplant-all" checked={all} onChange={() => setAll(true)} />
              <label className="form-check-label" htmlFor="transplant-all">
                Yes, that was all {total}. Finish them in the nursery.
              </label>
            </div>
            {total > 1 && (
              <div className="form-check mt-2">
                <input className="form-check-input" type="radio" id="transplant-some" checked={!all} onChange={() => setAll(false)} />
                <label className="form-check-label" htmlFor="transplant-some">
                  No, only some. The rest stay in the nursery.
                </label>
              </div>
            )}
            {!all && (
              <div className="ms-4 mt-2">
                <label className="form-label" htmlFor="transplant-count">How many did you transplant?</label>
                <input
                  id="transplant-count"
                  className="form-control w-auto"
                  type="number"
                  min="1"
                  max={total - 1}
                  value={count}
                  onChange={(event) => setCount(Math.min(total - 1, Math.max(1, parseInt(event.target.value, 10) || 1)))}
                />
              </div>
            )}
          </fieldset>
        )}
      </div>
      <div className="modal-footer">
        <button type="button" className="btn btn-link" onClick={onClose} disabled={saving}>Cancel</button>
        {step === 2 && <button type="button" className="btn btn-outline-success" onClick={() => setStep(1)} disabled={saving}>Back</button>}
        {step === 1 ? (
          <button
            type="button"
            className="btn btn-success"
            onClick={() => setStep(2)}
            disabled={!garden || !movedOn || movedOn > today}
          >
            Next
          </button>
        ) : (
          <button type="button" className="btn btn-success" onClick={save} disabled={saving} aria-busy={saving}>Transplant</button>
        )}
      </div>
    </Modal>
  );
}
