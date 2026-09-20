import React, {useEffect, useState} from 'react';

import {getJson, postJson} from '../api';
import Modal from './Modal';
import PlantPartPicker from './PlantPartPicker';
import Steps from './Steps';

const STEPS = ['Choose a part', 'How much?'];

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

// Recording a harvest from a garden card, as a dialog over the list, in the same
// two steps as the Add planting dialog: say which part of the plant you
// harvested, then how much. The crop is the planting's and the date is today.
// It loads those, and the choices, from /plantings/:slug/harvests/new.json, saves
// with POST /harvests.json, and hands the refreshed garden card to onSaved, so
// the planting's badges follow and the page is never left.
export default function RecordHarvestModal({planting, iconUrl, onClose, onSaved}) {
  const [form, setForm] = useState(null); // {planting_id, plant_parts, plant_part_id (the usual one), units, weight_units, ...}
  const [values, setValues] = useState(null);
  const [part, setPart] = useState(null); // step 1's answer
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
      const {ok, status, data} = await postJson('/harvests.json', {
        harvest: {planting_id: form.planting_id, plant_part_id: part.id, ...values},
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

  const title = (
    <>
      {iconUrl && <img src={iconUrl} alt="" className="modal-title-icon" />}
      Record a harvest of {planting.crop.name}
    </>
  );

  return (
    <Modal title={title} titleId={`record-harvest-title-${planting.id}`} onClose={onClose}>
      {loadError && (
        <div className="modal-body">
          <div className="alert alert-danger mb-0" role="alert">Couldn&rsquo;t load the harvest form. Please close this and try again.</div>
        </div>
      )}
      {!loadError && !values && (
        <div className="modal-body" role="status"><i className="fa fa-spinner fa-spin" aria-hidden="true" /> Loading…</div>
      )}
      {values && !part && (
        <>
          <div className="modal-body plant-dialog-body">
            <Steps steps={STEPS} current={1} />
            <PlantPartPicker id="record-harvest-part" parts={form.plant_parts} suggestedId={form.plant_part_id} onChoose={setPart} />
          </div>
          <div className="modal-footer">
            <button type="button" className="btn btn-link" onClick={onClose}>Cancel</button>
          </div>
        </>
      )}
      {values && part && (
        <form onSubmit={save}>
          <div className="modal-body plant-dialog-body">
            <Steps steps={STEPS} current={2} />
            {errors.length > 0 && (
              <div className="alert alert-danger" role="alert">
                <i className="fa fa-exclamation-triangle" aria-hidden="true" />{' '}
                <strong>That didn&rsquo;t save.</strong>
                <ul className="mb-0">{errors.map((message) => <li key={message}>{message}</li>)}</ul>
                <span>What you entered is kept, so you can press Save harvest to try again.</span>
              </div>
            )}

            <div className="crop-confirm mb-4">
              <dl className="crop-confirm-details">
                <dt>Crop</dt>
                <dd>{planting.crop.name}</dd>
                <dt>Part</dt>
                <dd className="crop-confirm-name">
                  {part.name}
                  <button type="button" className="btn btn-sm btn-outline-secondary" onClick={() => setPart(null)} disabled={saving}>
                    <i className="fa fa-edit" aria-hidden="true" /> Change<span className="visually-hidden"> plant part</span>
                  </button>
                </dd>
              </dl>
            </div>

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
            </div>

            <div>
              <label className="form-label" htmlFor="record-harvest-notes">Notes</label>
              <textarea id="record-harvest-notes" className="form-control" rows="2" value={values.description} onChange={set('description')} />
            </div>
          </div>
          <div className="modal-footer">
            <button type="button" className="btn btn-link" onClick={onClose} disabled={saving}>Cancel</button>
            <button type="submit" className="btn btn-success btn-plant" disabled={saving} aria-busy={saving}>
              {saving ? <><i className="fa fa-spinner fa-spin" aria-hidden="true" /> Saving…</> : 'Save harvest'}
            </button>
          </div>
        </form>
      )}
    </Modal>
  );
}
