import React, {useEffect, useState} from 'react';

import {getJson, postJson} from '../api';
import {formatDate} from '../dates';
import Modal from './Modal';
import PlantPartPicker from './PlantPartPicker';
import Steps from './Steps';

const STEPS = ['Choose a part', 'How much?', 'When?', 'Any notes?'];
const WHEN_CHOICES = [['today', 'Today'], ['yesterday', 'Yesterday'], ['other', 'Enter date']];

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

// "2026-09-21" a number of days earlier (or later, if negative), as
// "2026-09-20". Worked out in UTC so the browser's time zone can't shift it.
function daysBefore(iso, days) {
  const [year, month, day] = iso.split('-').map(Number);
  return new Date(Date.UTC(year, month - 1, day - days)).toISOString().slice(0, 10);
}

// Recording a harvest from a garden card, as a dialog over the list, in steps
// like the Add planting dialog: which part of the plant you harvested, how
// much, when (today unless you say otherwise), then any notes, and save. The
// crop is the planting's.
// It loads that, and the choices, from /plantings/:slug/harvests/new.json, saves
// with POST /harvests.json, and hands the refreshed garden card to onSaved, so
// the planting's badges follow and the page is never left.
export default function RecordHarvestModal({planting, iconUrl, onClose, onSaved}) {
  const [form, setForm] = useState(null); // {planting_id, plant_parts, plant_part_id (the usual one), units, weight_units, ...}
  const [values, setValues] = useState(null);
  const [part, setPart] = useState(null); // step 1's answer
  const [step, setStep] = useState(1);
  const [when, setWhen] = useState('today'); // today, yesterday, or other (a date you enter)
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
          custom_date: '',
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

  // The server's "today" is the one that counts, not the browser's.
  const today = form && form.harvested_at;
  const harvestedAt = {today, yesterday: today && daysBefore(today, 1), other: values && values.custom_date}[when];

  // A harvest has to come after the planting (the server checks), so there is
  // nothing to offer before that: no Yesterday for a planting made yesterday
  // or today, and the date box starts the day after it was planted.
  const plantedOn = planting.planted_at;
  const choices = WHEN_CHOICES.filter(([choice]) => choice !== 'yesterday' || !plantedOn || (today && daysBefore(today, 1) > plantedOn));
  const earliest = plantedOn ? daysBefore(plantedOn, -1) : undefined;

  function choosePart(chosen) {
    setPart(chosen);
    setStep(2);
  }

  function chooseWhen(choice) {
    setWhen(choice);
    if (choice === 'other' && !values.custom_date) setValues((current) => ({...current, custom_date: today}));
  }

  function amount() {
    const unit = form.units.find((candidate) => candidate.value === values.unit);
    const parts = [
      values.quantity && `${values.quantity} ${unit ? unit.label : values.unit}`,
      values.weight_quantity && `${values.weight_quantity} ${values.weight_unit}`,
    ].filter(Boolean);
    return parts.length > 0 ? parts.join(' · ') : 'Not entered';
  }

  // "Today, 21 Sep", or just the date when you entered one.
  function whenLabel() {
    const date = formatDate(harvestedAt);
    return when === 'other' ? date : `${WHEN_CHOICES.find(([value]) => value === when)[1]}, ${date}`;
  }

  // Each step's button goes on to the next; the last one saves.
  async function save(event) {
    event.preventDefault();
    if (step < STEPS.length) {
      setStep(step + 1);
      return;
    }
    setSaving(true);
    setErrors([]);
    try {
      const {custom_date: customDate, ...fields} = values;
      const {ok, status, data} = await postJson('/harvests.json', {
        harvest: {planting_id: form.planting_id, plant_part_id: part.id, harvested_at: harvestedAt, ...fields},
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
      {values && step === 1 && (
        <div className="modal-body plant-dialog-body">
          <Steps steps={STEPS} current={1} />
          <PlantPartPicker id="record-harvest-part" parts={form.plant_parts} suggestedId={form.plant_part_id} onChoose={choosePart} />
        </div>
      )}
      {values && step > 1 && (
        <form onSubmit={save}>
          <div className="modal-body plant-dialog-body">
            <Steps steps={STEPS} current={step} />
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
                <dd className={step === 2 ? 'crop-confirm-name' : undefined}>
                  {part.name}
                  <button type="button" className="btn btn-sm btn-outline-secondary ms-3" onClick={() => setStep(1)} disabled={saving}>
                    <i className="fa fa-edit" aria-hidden="true" /> Change<span className="visually-hidden"> plant part</span>
                  </button>
                </dd>
                {step > 2 && (
                  <>
                    <dt>Amount</dt>
                    <dd>
                      {amount()}
                      <button type="button" className="btn btn-sm btn-outline-secondary ms-3" onClick={() => setStep(2)} disabled={saving}>
                        <i className="fa fa-edit" aria-hidden="true" /> Change<span className="visually-hidden"> amount</span>
                      </button>
                    </dd>
                  </>
                )}
                {step > 3 && (
                  <>
                    <dt>When</dt>
                    <dd>
                      {whenLabel()}
                      <button type="button" className="btn btn-sm btn-outline-secondary ms-3" onClick={() => setStep(3)} disabled={saving}>
                        <i className="fa fa-edit" aria-hidden="true" /> Change<span className="visually-hidden"> when</span>
                      </button>
                    </dd>
                  </>
                )}
              </dl>
            </div>

            {step === 2 && (
              <>
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
              </>
            )}

            {step === 3 && (
              <fieldset>
                <legend className="crop-picker-label when-legend">When did you harvest it?</legend>
                <div className="when-choices">
                  {choices.map(([choice, label]) => (
                    <React.Fragment key={choice}>
                      <input
                        type="radio"
                        className="visually-hidden"
                        name="record-harvest-when"
                        id={`record-harvest-when-${choice}`}
                        checked={when === choice}
                        onChange={() => chooseWhen(choice)}
                        autoFocus={choice === 'today'}
                      />
                      <label className="when-choice" htmlFor={`record-harvest-when-${choice}`}>{label}</label>
                    </React.Fragment>
                  ))}
                </div>
                {when === 'other' ? (
                  <div className="mt-3">
                    <label className="form-label" htmlFor="record-harvest-date">Date</label>
                    <input
                      id="record-harvest-date"
                      type="date"
                      className="form-control when-date"
                      value={values.custom_date}
                      min={earliest}
                      onChange={set('custom_date')}
                      required
                      autoFocus
                    />
                  </div>
                ) : (
                  <p className="when-hint">{harvestedAt && formatDate(harvestedAt)}</p>
                )}
              </fieldset>
            )}

            {step === 4 && (
              <div>
                <label className="crop-picker-label" htmlFor="record-harvest-notes">Any notes?</label>
                <textarea
                  id="record-harvest-notes"
                  className="form-control"
                  rows="3"
                  placeholder="Optional. How did it go?"
                  value={values.description}
                  onChange={set('description')}
                  // Enter is a new line here, so Ctrl or Cmd with Enter saves.
                  onKeyDown={(event) => {
                    if (event.key === 'Enter' && (event.ctrlKey || event.metaKey)) {
                      event.preventDefault();
                      event.currentTarget.form.requestSubmit();
                    }
                  }}
                  autoFocus
                />
              </div>
            )}
          </div>
          <div className="modal-footer">
            {step > 2 && <button type="button" className="btn btn-link" onClick={() => setStep(step - 1)} disabled={saving}>Back</button>}
            {step < STEPS.length && <button type="submit" className="btn btn-success btn-plant">Next</button>}
            {step === STEPS.length && (
              <button type="submit" className="btn btn-success btn-plant" disabled={saving || !harvestedAt} aria-busy={saving}>
                {saving ? <><i className="fa fa-spinner fa-spin" aria-hidden="true" /> Saving…</> : 'Save harvest'}
              </button>
            )}
          </div>
        </form>
      )}
    </Modal>
  );
}
