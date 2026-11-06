import React, {useState} from 'react';

import {postJson} from '../api';
import {daysBefore, localToday} from '../dates';
import {errorMessages} from '../errors';
import Modal from './Modal';
import WhenPicker from './WhenPicker';

const WHEN_CHOICES = [['today', 'Today'], ['tomorrow', 'Tomorrow'], ['other', 'Another day']];

// Adding a job, as a dialog over the page: what needs doing, when, and a note
// if they want one. Saves with POST /jobs.json and hands the job to onSaved.
export default function AddJobModal({onClose, onSaved}) {
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [noting, setNoting] = useState(false); // the notes box is open
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
        job: {name, description, due_date: dueOn},
      });
      if (ok) {
        onSaved(data);
        return;
      }
      setErrors(errorMessages(status, data, {signedOut: 'Please sign in again to add this job.'}));
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
          <div className="mb-3">
            <label htmlFor="add-job-name" className="visually-hidden">What needs doing?</label>
            <input
              id="add-job-name"
              className="form-control form-control-lg"
              placeholder="What needs doing?"
              aria-describedby="add-job-hint"
              value={name}
              onChange={(event) => setName(event.target.value)}
              required
              autoFocus
            />
            <p id="add-job-hint" className="step-hint mb-0 mt-2">Water the seedlings, build a trellis for the peas…</p>
          </div>
          <WhenPicker
            id="add-job"
            legend="When?"
            hideLegend
            choices={WHEN_CHOICES}
            when={when}
            onWhen={chooseWhen}
            date={customDate}
            onDate={(event) => setCustomDate(event.target.value)}
            hint={dueOn}
          />
          {noting ? (
            <div className="mt-3">
              <label htmlFor="add-job-notes" className="visually-hidden">Notes</label>
              <textarea
                id="add-job-notes"
                className="form-control"
                rows="3"
                placeholder="Note"
                value={description}
                onChange={(event) => setDescription(event.target.value)}
                autoFocus
              />
            </div>
          ) : (
            <button type="button" className="btn btn-link ps-0 mt-2" onClick={() => setNoting(true)}>
              <i className="fas fa-plus" aria-hidden="true" /> Add a note
            </button>
          )}
        </div>
        <div className="modal-footer">
          <span className="me-auto step-hint"><i className="fas fa-globe" aria-hidden="true" /> Jobs are public</span>
          <button type="button" className="btn btn-link" onClick={onClose} disabled={saving}>Cancel</button>
          <button type="submit" className="btn btn-success btn-plant" disabled={saving} aria-busy={saving}>
            {saving ? <><i className="fas fa-spinner fa-spin" aria-hidden="true" /> Saving…</> : 'Add job'}
          </button>
        </div>
      </form>
    </Modal>
  );
}
