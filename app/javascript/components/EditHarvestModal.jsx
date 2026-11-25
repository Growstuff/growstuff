import React, {useEffect, useState} from 'react';

import {getJson, patchJson} from '../api';
import {daysBefore} from '../dates';
import {errorMessages} from '../errors';
import Modal from './Modal';

// Changing a harvest from its planting's timeline, as one dialog over the page: the part, how much, when and any
// notes. `harvest` is what it says now ({slug, plant_part_id, quantity, unit, weight_quantity, weight_unit, harvested_at,
// description}), from the edit link. The choices for the selects come from /plantings/:slug/harvests/new.json, as for
// recording one, and it saves with PATCH /harvests/:slug.json.
export default function EditHarvestModal({planting, harvest, onClose, onSaved}) {
  const [form, setForm] = useState(null); // {harvested_at (the server's today), plant_parts, units, weight_units}
  const [values, setValues] = useState({
    plant_part_id: harvest.plant_part_id || '',
    quantity: harvest.quantity ?? '',
    unit: harvest.unit || '',
    weight_quantity: harvest.weight_quantity ?? '',
    weight_unit: harvest.weight_unit || '',
    harvested_at: harvest.harvested_at || '',
    description: harvest.description || '',
  });
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
        // A harvest with no amount has no unit saved: start from the first, as for a new one.
        setValues((current) => ({
          ...current,
          unit: current.unit || data.units[0].value,
          weight_unit: current.weight_unit || data.weight_units[0].value,
        }));
      } catch (error) {
        if (error.name !== 'AbortError') setLoadError(true);
      }
    })();
    return () => controller.abort();
  }, [planting.url]);

  const set = (field) => (event) => setValues((current) => ({...current, [field]: event.target.value}));
  const earliest = planting.planted_at ? daysBefore(planting.planted_at, -1) : undefined;

  async function save(event) {
    event.preventDefault();
    setSaving(true);
    setErrors([]);
    try {
      const {ok, status, data} = await patchJson(`/harvests/${harvest.slug}.json`, {harvest: values});
      if (ok) {
        onSaved(); // closes this dialog
        return;
      }
      setErrors(errorMessages(status, data, {signedOut: 'Please sign in again to save this harvest.', forbidden: 'You can\'t change this harvest.'}));
    } catch (error) {
      setErrors(['Couldn\'t reach the server. Please try again.']);
    }
    setSaving(false);
  }

  return (
    <Modal title={`Edit harvest of ${planting.crop.name}`} titleId={`edit-harvest-title-${harvest.slug}`} onClose={onClose}>
      {loadError && (
        <div className="modal-body">
          <div className="alert alert-danger mb-0" role="alert">Couldn&rsquo;t load the harvest form. Please close this and try again.</div>
        </div>
      )}
      {!loadError && !form && (
        <div className="modal-body" role="status"><i className="fas fa-spinner fa-spin" aria-hidden="true" /> Loading…</div>
      )}
      {form && (
        <form onSubmit={save}>
          <div className="modal-body plant-dialog-body">
            {errors.length > 0 && (
              <div className="alert alert-danger" role="alert">
                <i className="fas fa-exclamation-triangle" aria-hidden="true" />{' '}
                <strong>That didn&rsquo;t save.</strong>
                <ul className="mb-0">{errors.map((message) => <li key={message}>{message}</li>)}</ul>
                <span>What you entered is kept, so you can press Save changes to try again.</span>
              </div>
            )}
            <div className="mb-3">
              <label className="form-label" htmlFor="edit-harvest-part">Part harvested</label>
              <select id="edit-harvest-part" className="form-select" value={values.plant_part_id} onChange={set('plant_part_id')} required>
                {form.plant_parts.map((part) => <option key={part.id} value={part.id}>{part.name}</option>)}
              </select>
            </div>
            <div className="row g-3 mb-3">
              <div className="col-md-4">
                <label className="form-label" htmlFor="edit-harvest-quantity">How many?</label>
                <input id="edit-harvest-quantity" type="number" min="0" step="any" className="form-control" value={values.quantity} onChange={set('quantity')} />
              </div>
              <div className="col-md-8">
                <label className="form-label" htmlFor="edit-harvest-unit">Counted as</label>
                <select id="edit-harvest-unit" className="form-select" value={values.unit} onChange={set('unit')}>
                  {form.units.map((unit) => <option key={unit.value} value={unit.value}>{unit.label}</option>)}
                </select>
              </div>
            </div>
            <div className="row g-3 mb-3">
              <div className="col-md-4">
                <label className="form-label" htmlFor="edit-harvest-weight">Weighing (in total)</label>
                <input id="edit-harvest-weight" type="number" min="0" step="any" className="form-control" value={values.weight_quantity} onChange={set('weight_quantity')} />
              </div>
              <div className="col-md-8">
                <label className="form-label" htmlFor="edit-harvest-weight-unit">Weighed in</label>
                <select id="edit-harvest-weight-unit" className="form-select" value={values.weight_unit} onChange={set('weight_unit')}>
                  {form.weight_units.map((unit) => <option key={unit.value} value={unit.value}>{unit.label}</option>)}
                </select>
              </div>
            </div>
            <div className="mb-3">
              <label className="form-label" htmlFor="edit-harvest-date">When</label>
              <input id="edit-harvest-date" type="date" className="form-control" value={values.harvested_at} onChange={set('harvested_at')} min={earliest} max={form.harvested_at} required />
            </div>
            <div>
              <label className="form-label" htmlFor="edit-harvest-notes">Notes <span className="text-muted">(optional)</span></label>
              <textarea id="edit-harvest-notes" className="form-control" rows="3" value={values.description} onChange={set('description')} />
            </div>
          </div>
          <div className="modal-footer">
            <button type="button" className="btn btn-link me-auto" onClick={onClose} disabled={saving}>Cancel</button>
            <button type="submit" className="btn btn-success btn-plant" disabled={saving || !values.harvested_at} aria-busy={saving}>
              {saving ? <><i className="fas fa-spinner fa-spin" aria-hidden="true" /> Saving…</> : 'Save changes'}
            </button>
          </div>
        </form>
      )}
    </Modal>
  );
}
