import React, {useEffect, useState} from 'react';

import {getJson, patchJson} from '../api';
import CropPicker from './CropPicker';
import Modal from './Modal';
import StarRating from './StarRating';

function humanize(field) {
  return field.replace(/_/g, ' ').replace(/^./, (c) => c.toUpperCase());
}

function errorMessages(status, data) {
  if (status === 422 && data && data.errors) {
    const messages = Object.entries(data.errors).flatMap(([field, list]) => list.map((m) => `${humanize(field)} ${m}`));
    if (messages.length > 0) return messages;
  }
  if (status === 401) return ['Please sign in again to save this planting.'];
  if (status === 403) return ['You can\'t change this planting.'];
  return ['Something went wrong saving that. Please try again.'];
}

// The same fields as the planting edit page, in a dialog over the garden list.
// It loads the planting's current values from /plantings/:slug/edit.json, saves
// with PATCH, and hands the refreshed garden card to onSaved, so the list
// updates in place and the page is never left.
export default function EditPlantingModal({planting, onClose, onSaved}) {
  const [form, setForm] = useState(null); // {planting, planted_from_values, sunniness_values}
  const [values, setValues] = useState(null);
  const [loadError, setLoadError] = useState(false);
  const [changingCrop, setChangingCrop] = useState(false);
  const [saving, setSaving] = useState(false);
  const [errors, setErrors] = useState([]);
  const cropName = planting.crop.name;

  useEffect(() => {
    const controller = new AbortController();
    (async () => {
      try {
        const {ok, data} = await getJson(`${planting.url}/edit.json`, {signal: controller.signal});
        if (!ok) throw new Error('load failed');
        setForm(data);
        setValues(data.planting);
      } catch (error) {
        if (error.name !== 'AbortError') setLoadError(true);
      }
    })();
    return () => controller.abort();
  }, [planting.url]);

  const set = (field) => (event) => {
    const {type, checked, value} = event.target;
    setValues((current) => ({...current, [field]: type === 'checkbox' ? checked : value}));
  };

  // As the edit page does: un-ticking "finished" clears the finished date.
  function setFinished(event) {
    const finished = event.target.checked;
    setValues((current) => ({...current, finished, finished_at: finished ? current.finished_at : ''}));
  }

  async function save(event) {
    event.preventDefault();
    setSaving(true);
    setErrors([]);
    const {crop, planted_at: plantedAt, planted_from: plantedFrom, sunniness, quantity,
      overall_rating: rating, description, finished, finished_at: finishedAt, failed} = values;
    const attributes = {
      crop_id: crop.id, planted_at: plantedAt, planted_from: plantedFrom, sunniness, quantity,
      overall_rating: rating, description, finished, finished_at: finishedAt, failed,
    };
    try {
      const {ok, status, data} = await patchJson(planting.url, {planting: attributes});
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

  const titleId = `edit-planting-title-${planting.id}`;

  return (
    <Modal title={`Edit ${cropName}`} titleId={titleId} onClose={onClose}>
      {loadError && (
        <div className="modal-body">
          <div className="alert alert-danger mb-0" role="alert">Couldn&rsquo;t load this planting. Please close this and try again.</div>
        </div>
      )}
      {!loadError && !values && (
        <div className="modal-body" role="status"><i className="fa fa-spinner fa-spin" aria-hidden="true" /> Loading…</div>
      )}
      {values && (
        <form onSubmit={save}>
          <div className="modal-body edit-planting-body">
            {errors.length > 0 && (
              <div className="alert alert-danger" role="alert">
                <strong>That didn&rsquo;t save.</strong>
                <ul className="mb-0">{errors.map((message) => <li key={message}>{message}</li>)}</ul>
              </div>
            )}

            <div className="mb-3">
              <span className="form-label d-block">What did you plant?</span>
              {changingCrop ? (
                <CropPicker id="edit-planting-crop" onChoose={(crop) => {
                  setValues({...values, crop: {id: crop.id, name: crop.name}});
                  setChangingCrop(false);
                }} />
              ) : (
                <>
                  <strong>{values.crop.name}</strong>{' '}
                  <button type="button" className="btn btn-sm btn-outline-secondary" onClick={() => setChangingCrop(true)}>
                    <i className="fa fa-edit" aria-hidden="true" /> Change<span className="visually-hidden"> crop</span>
                  </button>
                </>
              )}
            </div>

            <div className="row g-3 mb-3">
              <div className="col-md-4">
                <label className="form-label" htmlFor="edit-planting-planted-at">When?</label>
                <input id="edit-planting-planted-at" type="date" className="form-control" value={values.planted_at || ''} onChange={set('planted_at')} />
              </div>
              <div className="col-md-4">
                <label className="form-label" htmlFor="edit-planting-planted-from">Planted from</label>
                <select id="edit-planting-planted-from" className="form-select" value={values.planted_from || ''} onChange={set('planted_from')}>
                  <option value="" />
                  {form.planted_from_values.map((value) => <option key={value} value={value}>{value}</option>)}
                </select>
              </div>
              <div className="col-md-4">
                <label className="form-label" htmlFor="edit-planting-sunniness">Sun or shade?</label>
                <select id="edit-planting-sunniness" className="form-select" value={values.sunniness || ''} onChange={set('sunniness')}>
                  <option value="" />
                  {form.sunniness_values.map((value) => <option key={value} value={value}>{value}</option>)}
                </select>
              </div>
            </div>

            <div className="row g-3 mb-3">
              <div className="col-md-4">
                <label className="form-label" htmlFor="edit-planting-quantity">How many?</label>
                <input id="edit-planting-quantity" type="number" min="1" className="form-control" value={values.quantity ?? ''} onChange={set('quantity')} />
              </div>
              <div className="col-md-8">
                <StarRating
                  id="edit-planting-rating"
                  label="Overall rating"
                  value={values.overall_rating}
                  onChange={(rating) => setValues({...values, overall_rating: rating})}
                />
              </div>
            </div>

            <div className="mb-3">
              <label className="form-label" htmlFor="edit-planting-description">Tell us more about it</label>
              <textarea id="edit-planting-description" className="form-control" rows="4" value={values.description || ''} onChange={set('description')} />
            </div>

            <div className="row g-3">
              <div className="col-md-6">
                <div className="form-check">
                  <input id="edit-planting-finished" type="checkbox" className="form-check-input" checked={!!values.finished} onChange={setFinished} />
                  <label className="form-check-label" htmlFor="edit-planting-finished">Mark as finished</label>
                </div>
                <div className="form-check">
                  <input id="edit-planting-failed" type="checkbox" className="form-check-input" checked={!!values.failed} onChange={set('failed')} />
                  <label className="form-check-label" htmlFor="edit-planting-failed">Mark as failed</label>
                </div>
              </div>
              <div className="col-md-6">
                <label className="form-label" htmlFor="edit-planting-finished-at">Finished date</label>
                <input id="edit-planting-finished-at" type="date" className="form-control" value={values.finished_at || ''} onChange={set('finished_at')} />
              </div>
            </div>
          </div>
          <div className="modal-footer">
            <button type="button" className="btn btn-link" onClick={onClose} disabled={saving}>Cancel</button>
            <button type="submit" className="btn btn-success" disabled={saving} aria-busy={saving}>
              {saving ? <><i className="fa fa-spinner fa-spin" aria-hidden="true" /> Saving…</> : 'Save'}
            </button>
          </div>
        </form>
      )}
    </Modal>
  );
}
