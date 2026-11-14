import React, {useState} from 'react';

import {postJson} from '../api';
import {localToday} from '../dates';
import {errorMessages} from '../errors';
import Modal from './Modal';
import WhenPicker from './WhenPicker';

const WHEN_CHOICES = [['today', 'Today'], ['other', 'Enter date']];

// Noting something about a planting, as a dialog over the page: what you saw,
// when, and a note if you want one. Saves with POST /plantings/:slug/observations.json
// and hands the garden's refreshed card to onSaved. `kinds` is [{value, label}]
// from the server, so the wording lives in one place.
export default function ObservationModal({planting, kinds, onClose, onSaved}) {
  const [kind, setKind] = useState('');
  const [when, setWhen] = useState('today');
  const [customDate, setCustomDate] = useState(localToday());
  const [description, setDescription] = useState('');
  const [saving, setSaving] = useState(false);
  const [errors, setErrors] = useState([]);

  const today = localToday();
  const inFuture = when === 'other' && customDate > today;

  async function save(event) {
    event.preventDefault();
    if (inFuture) return;
    setSaving(true);
    setErrors([]);
    // Today, however it was chosen, is left for the server to stamp, so the time of day is the real one (and a
    // member's today can be a day ahead of the server's).
    // "Other" is no kind at all.
    const observation = {kind: kind === 'other' ? null : kind, description, ...(when === 'other' && customDate !== today ? {observed_at: customDate} : {})};
    try {
      const {ok, status, data} = await postJson(`${planting.url}/observations.json`, {observation});
      if (ok) {
        onSaved(data.garden); // closes this dialog
        return;
      }
      setErrors(errorMessages(status, data, {signedOut: 'Please sign in again to add this observation.', forbidden: 'You can\'t change this planting.'}));
    } catch (error) {
      setErrors(['Couldn\'t reach the server. Please try again.']);
    }
    setSaving(false);
  }

  return (
    <Modal title={`Add observation to ${planting.crop.name}`} titleId={`add-observation-title-${planting.id}`} onClose={onClose}>
      <form onSubmit={save}>
        <div className="modal-body plant-dialog-body">
          {errors.length > 0 && (
            <div className="alert alert-danger" role="alert">
              <i className="fas fa-exclamation-triangle" aria-hidden="true" />{' '}
              <strong>That didn&rsquo;t save.</strong>
              <ul className="mb-0">{errors.map((message) => <li key={message}>{message}</li>)}</ul>
              <span>What you entered is kept, so you can press Add observation to try again.</span>
            </div>
          )}
          <fieldset className="mb-3">
            <legend className="crop-picker-label step-legend">What did you notice?</legend>
            <div className="pill-choices">
              {kinds.map((choice) => (
                <React.Fragment key={choice.value}>
                  <input
                    type="radio"
                    className="visually-hidden"
                    name="observation-kind"
                    id={`observation-kind-${choice.value}`}
                    checked={kind === choice.value}
                    onChange={() => setKind(choice.value)}
                    required
                  />
                  <label className="pill-choice" htmlFor={`observation-kind-${choice.value}`}>{choice.label}</label>
                </React.Fragment>
              ))}
            </div>
          </fieldset>
          <WhenPicker
            id="observation"
            legend="When?"
            choices={WHEN_CHOICES}
            when={when}
            onWhen={setWhen}
            date={customDate}
            onDate={(event) => setCustomDate(event.target.value)}
            max={today}
            hint={when === 'today' ? today : customDate}
          />
          {inFuture && <p className="text-danger small mt-2 mb-0" role="alert">Observations are for today or earlier, not the future.</p>}
          <div className="mt-3">
            <label htmlFor="observation-note" className="form-label">Note <span className="text-muted">(optional)</span></label>
            <textarea
              id="observation-note"
              className="form-control"
              rows="3"
              placeholder="What did it look like?"
              value={description}
              onChange={(event) => setDescription(event.target.value)}
            />
          </div>
        </div>
        <div className="modal-footer">
          <span className="me-auto step-hint"><i className="fas fa-globe" aria-hidden="true" /> Observations are public</span>
          <button type="button" className="btn btn-link" onClick={onClose} disabled={saving}>Cancel</button>
          <button type="submit" className="btn btn-success btn-plant" disabled={saving || !kind || inFuture} aria-busy={saving}>
            {saving ? <><i className="fas fa-spinner fa-spin" aria-hidden="true" /> Saving…</> : 'Add observation'}
          </button>
        </div>
      </form>
    </Modal>
  );
}
