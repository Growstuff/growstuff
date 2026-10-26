import React, {useState} from 'react';

import {postJson} from '../api';
import {daysBefore, localToday} from '../dates';
import Modal from './Modal';
import WhenPicker from './WhenPicker';

const WHEN_CHOICES = [['today', 'Today'], ['tomorrow', 'Tomorrow'], ['other', 'Enter date']];

function humanize(field) {
  return field.replace(/_/g, ' ').replace(/^./, (c) => c.toUpperCase());
}

function errorMessages(status, data) {
  if (status === 422 && data && data.errors) {
    const messages = Object.entries(data.errors).flatMap(([field, list]) => list.map((m) => `${humanize(field)} ${m}`));
    if (messages.length > 0) return messages;
  }
  if (status === 401) return ['Please sign in again to add this job.'];
  return ['Something went wrong saving that. Please try again.'];
}

// Adding a job, as a dialog over the page: what needs doing, when, in which
// garden if they have more than one, and any notes. Saves with POST /jobs.json
// and hands the job to onSaved.
//
// gardens: [{id, name}], their gardens.
export default function AddJobModal({gardens = [], onClose, onSaved}) {
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [gardenId, setGardenId] = useState('');
  const [when, setWhen] = useState('today');
  const [customDate, setCustomDate] = useState('');
  const [saving, setSaving] = useState(false);
  const [errors, setErrors] = useState([]);

  const today = localToday();
  const dueOn = {today, tomorrow: daysBefore(today, -1), other: customDate}[when];

  function chooseWhen(choice) {
    setWhen(choice);
    if (choice === 'other' && !customDate) setCustomDate(today);
  }

  async function save(event) {
    event.preventDefault();
    setSaving(true);
    setErrors([]);
    try {
      const {ok, status, data} = await postJson('/jobs.json', {
        job: {name, description, due_date: dueOn, garden_id: gardenId || undefined},
      });
      if (ok) {
        onSaved(data);
        return;
      }
      setErrors(errorMessages(status, data));
    } catch (error) {
      setErrors(['Couldn\'t reach the server. Please try again.']);
    }
    setSaving(false);
  }

  return (
    <Modal title="Add a job" titleId="add-job-title" onClose={onClose}>
      <form onSubmit={save}>
        <div className="modal-body plant-dialog-body">
          {errors.length > 0 && (
            <div className="alert alert-danger" role="alert">
              <i className="fas fa-exclamation-triangle" aria-hidden="true" />{' '}
              <strong>That didn&rsquo;t save.</strong>
              <ul className="mb-0">{errors.map((message) => <li key={message}>{message}</li>)}</ul>
            </div>
          )}
          <div className="mb-4">
            <label htmlFor="add-job-name" className="crop-picker-label">What needs doing?</label>
            <input
              id="add-job-name"
              className="form-control"
              placeholder="Water the seedlings, build a trellis…"
              value={name}
              onChange={(event) => setName(event.target.value)}
              required
              autoFocus
            />
          </div>
          <div className="mb-4">
            <WhenPicker
              id="add-job"
              legend="When?"
              choices={WHEN_CHOICES}
              when={when}
              onWhen={chooseWhen}
              date={customDate}
              onDate={(event) => setCustomDate(event.target.value)}
              hint={dueOn}
            />
          </div>
          {gardens.length > 1 && (
            <div className="mb-4">
              <label htmlFor="add-job-garden" className="crop-picker-label">Which garden?</label>
              <select id="add-job-garden" className="form-select" value={gardenId} onChange={(event) => setGardenId(event.target.value)}>
                <option value="">Any garden</option>
                {gardens.map((garden) => <option key={garden.id} value={garden.id}>{garden.name}</option>)}
              </select>
            </div>
          )}
          <label htmlFor="add-job-notes" className="crop-picker-label">Any notes?</label>
          <textarea
            id="add-job-notes"
            className="form-control"
            rows="3"
            placeholder="Optional."
            value={description}
            onChange={(event) => setDescription(event.target.value)}
          />
        </div>
        <div className="modal-footer">
          <button type="button" className="btn btn-link" onClick={onClose} disabled={saving}>Cancel</button>
          <button type="submit" className="btn btn-success btn-plant" disabled={saving} aria-busy={saving}>
            {saving ? <><i className="fas fa-spinner fa-spin" aria-hidden="true" /> Saving…</> : 'Add job'}
          </button>
        </div>
      </form>
    </Modal>
  );
}
