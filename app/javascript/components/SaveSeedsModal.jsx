import React, {useEffect, useState} from 'react';

import {getJson, postJson} from '../api';
import Modal from './Modal';
import Steps from './Steps';

const STEPS = ['How many?', 'Trade?', 'Any notes?'];
const QUICK_AMOUNTS = [10, 50, 100, 500, 1000];
const TRADE_LABELS = {nowhere: 'Not for trade', locally: 'Locally', nationally: 'Nationally', internationally: 'Internationally'};
const tradeLabel = (value) => TRADE_LABELS[value] || value;

function humanize(field) {
  return field.replace(/_/g, ' ').replace(/^./, (c) => c.toUpperCase());
}

function errorMessages(status, data) {
  if (status === 422 && data && data.errors) {
    const messages = Object.entries(data.errors).flatMap(([field, list]) => list.map((m) => `${humanize(field)} ${m}`));
    if (messages.length > 0) return messages;
  }
  if (status === 401) return ['Please sign in again to save these seeds.'];
  return ['Something went wrong saving that. Please try again.'];
}

// Saving seeds from a planting, as a dialog over the garden list, in steps like
// the record harvest dialog: about how many, whether to offer them for trade,
// then any notes. The crop is the planting's and the date is today; the rest
// (organic, source and so on) can be filled in later on the seed itself.
// It loads those, and the choices, from /plantings/:slug/seeds/new.json, saves with
// POST /seeds.json, and hands the new seed's link to onSaved, so the page is never left.
export default function SaveSeedsModal({planting, iconUrl, onClose, onSaved}) {
  const [form, setForm] = useState(null); // {crop, parent_planting_id, saved_at, tradable_to_values, location, settings_url}
  const [values, setValues] = useState(null);
  const [step, setStep] = useState(1);
  const [loadError, setLoadError] = useState(false);
  const [saving, setSaving] = useState(false);
  const [errors, setErrors] = useState([]);

  useEffect(() => {
    const controller = new AbortController();
    (async () => {
      try {
        const {ok, data} = await getJson(`${planting.url}/seeds/new.json`, {signal: controller.signal});
        if (!ok) throw new Error('load failed');
        setForm(data);
        setValues({quantity: '', tradable_to: 'nowhere', description: ''});
      } catch (error) {
        if (error.name !== 'AbortError') setLoadError(true);
      }
    })();
    return () => controller.abort();
  }, [planting.url]);

  const set = (field) => (event) => setValues((current) => ({...current, [field]: event.target.value}));

  const amount = () => (values.quantity === '' ? 'Not sure' : `About ${Number(values.quantity).toLocaleString()}`);

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
      const {ok, status, data} = await postJson('/seeds.json', {
        seed: {parent_planting_id: form.parent_planting_id, saved_at: form.saved_at, ...values},
      });
      if (ok) {
        onSaved(data.seed); // closes this dialog
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
      Save {planting.crop.name} seeds
    </>
  );

  const change = (toStep, what) => (
    <button type="button" className="btn btn-sm btn-outline-secondary ms-3" onClick={() => setStep(toStep)} disabled={saving}>
      <i className="fas fa-edit" aria-hidden="true" /> Change<span className="visually-hidden"> {what}</span>
    </button>
  );

  return (
    <Modal title={title} titleId={`save-seeds-title-${planting.id}`} onClose={onClose}>
      {loadError && (
        <div className="modal-body">
          <div className="alert alert-danger mb-0" role="alert">Couldn&rsquo;t load the seed form. Please close this and try again.</div>
        </div>
      )}
      {!loadError && !values && (
        <div className="modal-body" role="status"><i className="fas fa-spinner fa-spin" aria-hidden="true" /> Loading…</div>
      )}
      {values && (
        <form onSubmit={save}>
          <div className="modal-body plant-dialog-body">
            <Steps steps={STEPS} current={step} />
            {errors.length > 0 && (
              <div className="alert alert-danger" role="alert">
                <i className="fas fa-exclamation-triangle" aria-hidden="true" />{' '}
                <strong>That didn&rsquo;t save.</strong>
                <ul className="mb-0">{errors.map((message) => <li key={message}>{message}</li>)}</ul>
                <span>What you entered is kept, so you can press Save seeds to try again.</span>
              </div>
            )}

            {step > 1 && (
              <div className="crop-confirm mb-4">
                <dl className="crop-confirm-details">
                  <dt>Crop</dt>
                  <dd>{planting.crop.name}</dd>
                  <dt>Amount</dt>
                  <dd>{amount()}{change(1, 'amount')}</dd>
                  {step > 2 && (
                    <>
                      <dt>Trade</dt>
                      <dd>{tradeLabel(values.tradable_to)}{change(2, 'trade')}</dd>
                    </>
                  )}
                </dl>
              </div>
            )}

            {step === 1 && (
              <div className="crop-picker">
                <label htmlFor="save-seeds-quantity" className="crop-picker-label">About how many seeds?</label>
                <div className="crop-picker-field">
                  <i className="fas fa-seedling crop-picker-icon" aria-hidden="true" />
                  <input
                    id="save-seeds-quantity"
                    type="number"
                    min="0"
                    step="1"
                    inputMode="numeric"
                    className="crop-picker-input"
                    placeholder="A rough number"
                    aria-describedby="save-seeds-hint"
                    value={values.quantity}
                    onChange={set('quantity')}
                    autoFocus
                  />
                </div>
                <div id="save-seeds-hint" className="crop-picker-hint">An estimate is fine. Leave it blank if you are not sure.</div>
                <div className="pill-choices mt-3">
                  {QUICK_AMOUNTS.map((number) => (
                    <button
                      key={number}
                      type="button"
                      className={`pill-choice${Number(values.quantity) === number ? ' pill-choice-selected' : ''}`}
                      onClick={() => setValues((current) => ({...current, quantity: String(number)}))}
                    >
                      About {number.toLocaleString()}
                    </button>
                  ))}
                </div>
              </div>
            )}

            {step === 2 && (
              <fieldset>
                <legend className="crop-picker-label step-legend">Would you like to offer them for trade?</legend>
                <div className="pill-choices">
                  {form.tradable_to_values.map((choice) => (
                    <React.Fragment key={choice}>
                      <input
                        type="radio"
                        className="visually-hidden"
                        name="save-seeds-trade"
                        id={`save-seeds-trade-${choice}`}
                        checked={values.tradable_to === choice}
                        onChange={() => setValues((current) => ({...current, tradable_to: choice}))}
                        autoFocus={choice === values.tradable_to}
                      />
                      <label className="pill-choice" htmlFor={`save-seeds-trade-${choice}`}>{tradeLabel(choice)}</label>
                    </React.Fragment>
                  ))}
                </div>
                <p className="step-hint">
                  {values.tradable_to === 'nowhere' && 'They stay in your seed stash. You can offer them for trade later.'}
                  {values.tradable_to !== 'nowhere' && form.location && `Offered from ${form.location}.`}
                  {values.tradable_to !== 'nowhere' && !form.location && (
                    <>
                      Trading goes by where you are, and you have not set your location.{' '}
                      <a href={form.settings_url} target="_blank" rel="noopener noreferrer">Set your location</a>
                    </>
                  )}
                </p>
              </fieldset>
            )}

            {step === 3 && (
              <div>
                <label className="crop-picker-label" htmlFor="save-seeds-notes">Any notes?</label>
                <textarea
                  id="save-seeds-notes"
                  className="form-control"
                  rows="3"
                  placeholder="Optional. Which plants they came from, how they were dried."
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
            {step > 1 && <button type="button" className="btn btn-link" onClick={() => setStep(step - 1)} disabled={saving}>Back</button>}
            {step < STEPS.length && <button type="submit" className="btn btn-success btn-plant">Next</button>}
            {step === STEPS.length && (
              <button type="submit" className="btn btn-success btn-plant" disabled={saving} aria-busy={saving}>
                {saving ? <><i className="fas fa-spinner fa-spin" aria-hidden="true" /> Saving…</> : 'Save seeds'}
              </button>
            )}
          </div>
        </form>
      )}
    </Modal>
  );
}
