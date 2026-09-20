import React, {useEffect, useState} from 'react';

import {getJson, postJson} from '../api';
import Modal from './Modal';

function humanize(field) {
  return field.replace(/_/g, ' ').replace(/^./, (c) => c.toUpperCase());
}

function errorMessages(status, data) {
  if (status === 422 && data && data.errors) {
    const messages = Object.entries(data.errors).flatMap(([field, list]) => list.map((m) => `${humanize(field)} ${m}`));
    if (messages.length > 0) return messages;
  }
  if (status === 401) return ['Please sign in again to record this harvest.'];
  return ['Something went wrong saving that. Please try again.'];
}

// Quick entry for a harvest, in a dialog over the garden list: the crop is the
// planting's, the date is today, and the plant part starts as what that crop is
// usually harvested for. It loads those from /plantings/:slug/harvests/new.json,
// saves with POST /harvests.json, and hands the refreshed garden card to onSaved,
// so the planting's badges follow and the page is never left.
export default function RecordHarvestModal({planting, onClose, onSaved}) {
  const [form, setForm] = useState(null); // {crop, planting_id, plant_parts, units, weight_units, ...}
  const [values, setValues] = useState(null);
  const [loadError, setLoadError] = useState(false);
  const [saving, setSaving] = useState(false);
  const [errors, setErrors] = useState([]);

  useEffect(() => {
    const controller = new AbortController();
    (async () => {
      try {
        const {ok, data} = await getJson(`${planting.url}/harvests/new.json`, {signal: controller.signal});
        if (!ok) throw new Error('load failed');
        setForm(data);
        setValues({
          harvested_at: data.harvested_at || '',
          plant_part_id: data.plant_part_id || '',
          quantity: '',
          unit: data.units[0].value,
          weight_quantity: '',
          weight_unit: data.weight_units[0].value,
          description: '',
        });
      } catch (error) {
        if (error.name !== 'AbortError') setLoadError(true);
      }
    })();
    return () => controller.abort();
  }, [planting.url]);

  const set = (field) => (event) => setValues((current) => ({...current, [field]: event.target.value}));

  async function save(event) {
    event.preventDefault();
    setSaving(true);
    setErrors([]);
    try {
      const {ok, status, data} = await postJson('/harvests.json', {harvest: {planting_id: form.planting_id, ...values}});
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
    <Modal title={`Record a harvest of ${planting.crop.name}`} titleId={`record-harvest-title-${planting.id}`} onClose={onClose}>
      {loadError && (
        <div className="modal-body">
          <div className="alert alert-danger mb-0" role="alert">Couldn&rsquo;t load the harvest form. Please close this and try again.</div>
        </div>
      )}
      {!loadError && !values && (
        <div className="modal-body" role="status"><i className="fa fa-spinner fa-spin" aria-hidden="true" /> Loading…</div>
      )}
      {values && (
        <form onSubmit={save}>
          <div className="modal-body record-harvest-body">
            {errors.length > 0 && (
              <div className="alert alert-danger" role="alert">
                <strong>That didn&rsquo;t save.</strong>
                <ul className="mb-0">{errors.map((message) => <li key={message}>{message}</li>)}</ul>
              </div>
            )}

            <div className="row g-3 mb-3">
              <div className="col-md-4">
                <label className="form-label" htmlFor="record-harvest-quantity">How many?</label>
                <input
                  id="record-harvest-quantity"
                  type="number"
                  min="0"
                  step="any"
                  className="form-control"
                  value={values.quantity}
                  onChange={set('quantity')}
                  autoFocus
                />
              </div>
              <div className="col-md-8">
                <label className="form-label" htmlFor="record-harvest-unit">Counted as</label>
                <select id="record-harvest-unit" className="form-select" value={values.unit} onChange={set('unit')}>
                  {form.units.map((unit) => <option key={unit.value} value={unit.value}>{unit.label}</option>)}
                </select>
              </div>
            </div>

            <div className="row g-3 mb-3">
              <div className="col-md-4">
                <label className="form-label" htmlFor="record-harvest-weight">Weighing (in total)</label>
                <input
                  id="record-harvest-weight"
                  type="number"
                  min="0"
                  step="any"
                  className="form-control"
                  value={values.weight_quantity}
                  onChange={set('weight_quantity')}
                />
              </div>
              <div className="col-md-8">
                <label className="form-label" htmlFor="record-harvest-weight-unit">Weighed in</label>
                <select id="record-harvest-weight-unit" className="form-select" value={values.weight_unit} onChange={set('weight_unit')}>
                  {form.weight_units.map((unit) => <option key={unit.value} value={unit.value}>{unit.label}</option>)}
                </select>
              </div>
            </div>

            <div className="row g-3 mb-3">
              <div className="col-md-4">
                <label className="form-label" htmlFor="record-harvest-date">When?</label>
                <input id="record-harvest-date" type="date" className="form-control" value={values.harvested_at} onChange={set('harvested_at')} required />
              </div>
              <div className="col-md-8">
                <label className="form-label" htmlFor="record-harvest-part">Harvested plant part</label>
                <select id="record-harvest-part" className="form-select" value={values.plant_part_id} onChange={set('plant_part_id')} required>
                  <option value="">Choose…</option>
                  {form.plant_parts.map((part) => <option key={part.id} value={part.id}>{part.name}</option>)}
                </select>
              </div>
            </div>

            <div>
              <label className="form-label" htmlFor="record-harvest-notes">Notes</label>
              <textarea id="record-harvest-notes" className="form-control" rows="2" value={values.description} onChange={set('description')} />
            </div>
          </div>
          <div className="modal-footer">
            <button type="button" className="btn btn-link" onClick={onClose} disabled={saving}>Cancel</button>
            <button type="submit" className="btn btn-success" disabled={saving} aria-busy={saving}>
              {saving ? <><i className="fa fa-spinner fa-spin" aria-hidden="true" /> Saving…</> : 'Save harvest'}
            </button>
          </div>
        </form>
      )}
    </Modal>
  );
}
