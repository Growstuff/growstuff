import React, {useEffect, useState} from 'react';

import {getJson, patchJson} from '../api';
import Modal from './Modal';

function humanize(field) {
  return field.replace(/_/g, ' ').replace(/^./, (c) => c.toUpperCase());
}

function errorMessages(status, data) {
  if (status === 422 && data && data.errors) {
    const messages = Object.entries(data.errors).flatMap(([field, list]) => list.map((m) => `${humanize(field)} ${m}`));
    if (messages.length > 0) return messages;
  }
  if (status === 401) return ['Please sign in again to save this garden.'];
  if (status === 403) return ['You can\'t change this garden.'];
  return ['Something went wrong saving that. Please try again.'];
}

// The same fields as the garden edit page, in a dialog over the garden list. It
// loads the garden's current values from /gardens/:slug/edit.json, saves with
// PATCH, and hands the refreshed garden card to onSaved, so the list updates in
// place and the page is never left.
export default function EditGardenModal({garden, onClose, onSaved}) {
  const [form, setForm] = useState(null); // {garden, area_units, garden_types, location_help, ...}
  const [values, setValues] = useState(null);
  const [loadError, setLoadError] = useState(false);
  const [saving, setSaving] = useState(false);
  const [errors, setErrors] = useState([]);

  useEffect(() => {
    const controller = new AbortController();
    (async () => {
      try {
        const {ok, data} = await getJson(`${garden.url}/edit.json`, {signal: controller.signal});
        if (!ok) throw new Error('load failed');
        setForm(data);
        setValues(data.garden);
      } catch (error) {
        if (error.name !== 'AbortError') setLoadError(true);
      }
    })();
    return () => controller.abort();
  }, [garden.url]);

  const set = (field) => (event) => {
    const {type, checked, value} = event.target;
    setValues((current) => ({...current, [field]: type === 'checkbox' ? checked : value}));
  };

  async function save(event) {
    event.preventDefault();
    setSaving(true);
    setErrors([]);
    const {name, description, location, area, area_unit: areaUnit, garden_type_id: gardenTypeId, active} = values;
    try {
      const {ok, status, data} = await patchJson(garden.url, {
        garden: {name, description, location, area, area_unit: areaUnit, garden_type_id: gardenTypeId, active},
      });
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

  return (
    <Modal title={`Edit ${garden.name}`} titleId={`edit-garden-title-${garden.id}`} onClose={onClose}>
      {loadError && (
        <div className="modal-body">
          <div className="alert alert-danger mb-0" role="alert">Couldn&rsquo;t load this garden. Please close this and try again.</div>
        </div>
      )}
      {!loadError && !values && (
        <div className="modal-body" role="status"><i className="fa fa-spinner fa-spin" aria-hidden="true" /> Loading…</div>
      )}
      {values && (
        <form onSubmit={save}>
          <div className="modal-body edit-garden-body">
            {errors.length > 0 && (
              <div className="alert alert-danger" role="alert">
                <strong>That didn&rsquo;t save.</strong>
                <ul className="mb-0">{errors.map((message) => <li key={message}>{message}</li>)}</ul>
              </div>
            )}

            <div className="mb-3">
              <label className="form-label" htmlFor="edit-garden-name">Name</label>
              <input id="edit-garden-name" type="text" className="form-control" maxLength="255" required value={values.name || ''} onChange={set('name')} />
            </div>

            <div className="mb-3">
              <label className="form-label" htmlFor="edit-garden-description">Description</label>
              <textarea
                id="edit-garden-description"
                className="form-control"
                rows="4"
                placeholder="Where is it? What does it look like? Do you have irrigation? What are your plans?"
                value={values.description || ''}
                onChange={set('description')}
              />
            </div>

            <div className="mb-3">
              <label className="form-label" htmlFor="edit-garden-location">Location</label>
              <input id="edit-garden-location" type="text" className="form-control" maxLength="255" aria-describedby="edit-garden-location-help" value={values.location || ''} onChange={set('location')} />
              <div id="edit-garden-location-help" className="form-text">
                {form.location_help}{' '}
                <a href={form.settings_url} target="_blank" rel="noopener noreferrer">{form.member_has_location ? 'Change your location.' : 'Set your location now.'}</a>
              </div>
            </div>

            <div className="row g-3 mb-3">
              <div className="col-md-5">
                <label className="form-label" htmlFor="edit-garden-area">Area</label>
                <input id="edit-garden-area" type="number" step="any" min="0" className="form-control" value={values.area ?? ''} onChange={set('area')} />
              </div>
              <div className="col-md-7">
                <label className="form-label" htmlFor="edit-garden-area-unit">Area unit</label>
                <select id="edit-garden-area-unit" className="form-select" value={values.area_unit || ''} onChange={set('area_unit')}>
                  {form.area_units.map((unit) => <option key={unit.value} value={unit.value}>{unit.label}</option>)}
                </select>
              </div>
            </div>

            <div className="mb-3">
              <label className="form-label" htmlFor="edit-garden-type">Garden type</label>
              <select id="edit-garden-type" className="form-select" value={values.garden_type_id ?? ''} onChange={set('garden_type_id')}>
                <option value="" />
                {form.garden_types.map((type) => <option key={type.id} value={type.id}>{type.name}</option>)}
              </select>
            </div>

            <div className="form-check">
              <input id="edit-garden-active" type="checkbox" className="form-check-input" checked={!!values.active} onChange={set('active')} />
              <label className="form-check-label" htmlFor="edit-garden-active">Active?</label>
              <div className="form-text">
                You can mark a garden as inactive if you no longer use it.
                Note: this will mark all plantings in the garden as &ldquo;finished&rdquo;.
              </div>
            </div>
          </div>
          <div className="modal-footer">
            <button type="submit" className="btn btn-success btn-plant" disabled={saving} aria-busy={saving}>
              {saving ? <><i className="fa fa-spinner fa-spin" aria-hidden="true" /> Saving…</> : 'Save garden'}
            </button>
          </div>
        </form>
      )}
    </Modal>
  );
}
