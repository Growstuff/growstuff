import React, {useState} from 'react';

import {patchJson} from '../api';
import {formatDate} from '../dates';
import Modal from './Modal';

// "2026-09-21" a number of days earlier (or later, if negative), as
// "2026-09-20". Worked out in UTC so the browser's time zone can't shift it.
function daysBefore(iso, days) {
  const [year, month, day] = iso.split('-').map(Number);
  return new Date(Date.UTC(year, month - 1, day - days)).toISOString().slice(0, 10);
}

function errorMessages(status, data) {
  if (status === 422 && data && data.errors) {
    const messages = Object.entries(data.errors).flatMap(([field, list]) => list.map((m) => `${field.replace(/_/g, ' ').replace(/^./, (c) => c.toUpperCase())} ${m}`));
    if (messages.length > 0) return messages;
  }
  if (status === 401) return ['Please sign in again to mark this as finished.'];
  if (status === 403) return ['You can\'t change this planting.'];
  return ['Something went wrong saving that. Please try again.'];
}

// Marking a planting finished, from a garden card, as a dialog over the list:
// one question, when it finished, which is today unless you say otherwise. It
// saves with PATCH /plantings/:slug.json and hands the garden's refreshed card
// to onSaved (the planting then leaves the list), so the page is never left.
//
// The server needs the finish to come after the planting, so today is not offered
// for a planting made today, and the date box starts the day after it was planted.
export default function MarkFinishedModal({planting, iconUrl, onClose, onSaved}) {
  const {today, planted_at: plantedOn} = planting;
  const earliest = plantedOn ? daysBefore(plantedOn, -1) : undefined;
  const todayAllowed = !plantedOn || today > plantedOn;

  const [when, setWhen] = useState(todayAllowed ? 'today' : 'other');
  const [customDate, setCustomDate] = useState(todayAllowed ? today : earliest);
  const [saving, setSaving] = useState(false);
  const [errors, setErrors] = useState([]);

  // The server's "today" is the one that counts, not the browser's.
  const finishedAt = when === 'today' ? today : customDate;
  const choices = [todayAllowed && ['today', 'Today'], ['other', 'Enter date']].filter(Boolean);

  async function save(event) {
    event.preventDefault();
    setSaving(true);
    setErrors([]);
    try {
      const {ok, status, data} = await patchJson(planting.url, {planting: {finished: true, finished_at: finishedAt}});
      if (ok) {
        onSaved(data.garden); // closes this dialog
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
      Mark {planting.crop.name} as finished
    </>
  );

  return (
    <Modal title={title} titleId={`mark-finished-title-${planting.id}`} onClose={onClose}>
      <form onSubmit={save}>
        <div className="modal-body plant-dialog-body">
          {errors.length > 0 && (
            <div className="alert alert-danger" role="alert">
              <i className="fa fa-exclamation-triangle" aria-hidden="true" />{' '}
              <strong>That didn&rsquo;t save.</strong>
              <ul className="mb-0">{errors.map((message) => <li key={message}>{message}</li>)}</ul>
              <span>What you entered is kept, so you can press Mark as finished to try again.</span>
            </div>
          )}
          <fieldset>
            <legend className="crop-picker-label step-legend">When did it finish?</legend>
            <div className="pill-choices">
              {choices.map(([choice, label]) => (
                <React.Fragment key={choice}>
                  <input
                    type="radio"
                    className="visually-hidden"
                    name="mark-finished-when"
                    id={`mark-finished-when-${choice}`}
                    checked={when === choice}
                    onChange={() => setWhen(choice)}
                    autoFocus={choice === when && choice === 'today'}
                  />
                  <label className="pill-choice" htmlFor={`mark-finished-when-${choice}`}>{label}</label>
                </React.Fragment>
              ))}
            </div>
            {when === 'other' ? (
              <div className="mt-3">
                <label className="form-label" htmlFor="mark-finished-date">Date</label>
                <input
                  id="mark-finished-date"
                  type="date"
                  className="form-control when-date"
                  value={customDate}
                  min={earliest}
                  onChange={(event) => setCustomDate(event.target.value)}
                  required
                  autoFocus
                />
              </div>
            ) : (
              <p className="step-hint">{formatDate(finishedAt)}</p>
            )}
          </fieldset>
          <p className="step-hint mb-0">It moves off your list of plantings in progress.</p>
        </div>
        <div className="modal-footer">
          <button type="submit" className="btn btn-success btn-plant" disabled={saving || !finishedAt} aria-busy={saving}>
            {saving ? <><i className="fa fa-spinner fa-spin" aria-hidden="true" /> Saving…</> : 'Mark as finished'}
          </button>
        </div>
      </form>
    </Modal>
  );
}
