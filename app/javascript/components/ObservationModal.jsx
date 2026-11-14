import React, {useState} from 'react';

import {patchJson, postJson} from '../api';
import {localToday} from '../dates';
import {errorMessages} from '../errors';
import Modal from './Modal';
import WhenPicker, {WHEN_CHOICES} from './WhenPicker';

// An observation can't be in the future, but it can be about yesterday: that is a date.
const CHOICES = WHEN_CHOICES.filter(([choice]) => choice !== 'yesterday');

// Noting something about a planting, as a dialog over the page: what you saw,
// when, and a note if you want one. Saves with POST /plantings/:slug/observations.json
// and hands the garden's refreshed card to onSaved. `kinds` is [{value, label, icon}]
// from the server, so the wording lives in one place. Given an `observation`
// ({id, kind, observed_on, description}) it edits that one instead, with PATCH.
export default function ObservationModal({planting, kinds, observation, onClose, onSaved}) {
  const editing = Boolean(observation);
  const today = localToday();
  const [kind, setKind] = useState(editing ? (observation.kind || 'other') : '');
  const [when, setWhen] = useState(!editing || observation.observed_on === today ? 'today' : 'other');
  const [customDate, setCustomDate] = useState(editing ? observation.observed_on : today);
  const [description, setDescription] = useState((editing && observation.description) || '');
  const [saving, setSaving] = useState(false);
  const [errors, setErrors] = useState([]);

  const inFuture = when === 'other' && customDate > today;
  const chosenDate = when === 'today' ? today : customDate;

  // What to tell the server about when. Today, however it was chosen, is left for the server to stamp, so the time
  // of day is the real one (and a member's today can be a day ahead of the server's): nothing for a new observation,
  // and null, which means now, for an old one moved to today. A date left as it was is not sent, so its time stays.
  function observedAt() {
    if (editing && chosenDate === observation.observed_on) return undefined;
    if (chosenDate === today) return editing ? null : undefined;
    return chosenDate;
  }

  async function save(event) {
    event.preventDefault();
    if (inFuture) return;
    setSaving(true);
    setErrors([]);
    const attributes = {
      kind: kind === 'other' ? null : kind, // "Other" is no kind at all
      description,
      observed_at: observedAt(),
    };
    const url = `${planting.url}/observations`;
    try {
      const {ok, status, data} = editing
        ? await patchJson(`${url}/${observation.id}.json`, {observation: attributes})
        : await postJson(`${url}.json`, {observation: attributes});
      if (ok) {
        onSaved(data.garden); // closes this dialog
        return;
      }
      setErrors(errorMessages(status, data, {signedOut: 'Please sign in again to save this observation.', forbidden: 'You can\'t change this planting.'}));
    } catch (error) {
      setErrors(['Couldn\'t reach the server. Please try again.']);
    }
    setSaving(false);
  }

  const title = editing ? `Edit observation of ${planting.crop.name}` : `Add observation to ${planting.crop.name}`;
  const submitLabel = editing ? 'Save changes' : 'Add observation';

  return (
    <Modal title={title} titleId={`observation-title-${planting.id}`} onClose={onClose}>
      <form onSubmit={save}>
        <div className="modal-body plant-dialog-body">
          {errors.length > 0 && (
            <div className="alert alert-danger" role="alert">
              <i className="fas fa-exclamation-triangle" aria-hidden="true" />{' '}
              <strong>That didn&rsquo;t save.</strong>
              <ul className="mb-0">{errors.map((message) => <li key={message}>{message}</li>)}</ul>
              <span>What you entered is kept, so you can press {submitLabel} to try again.</span>
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
                  <label className="pill-choice" htmlFor={`observation-kind-${choice.value}`}>
                    <i className={`fas fa-${choice.icon}`} aria-hidden="true" /> {choice.label}
                  </label>
                </React.Fragment>
              ))}
            </div>
          </fieldset>
          <WhenPicker
            id="observation"
            legend="When?"
            choices={CHOICES}
            when={when}
            onWhen={setWhen}
            date={customDate}
            onDate={(event) => setCustomDate(event.target.value)}
            max={today}
            hint={chosenDate}
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
            {saving ? <><i className="fas fa-spinner fa-spin" aria-hidden="true" /> Saving…</> : submitLabel}
          </button>
        </div>
      </form>
    </Modal>
  );
}
