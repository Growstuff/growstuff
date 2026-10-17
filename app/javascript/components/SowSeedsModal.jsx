import React, {useState} from 'react';

import {postJson} from '../api';
import {daysBefore, localToday} from '../dates';
import CropDetails from './CropDetails';
import CropPicker from './CropPicker';
import SeedPacket from './SeedPacket';
import Modal from './Modal';
import WhenPicker from './WhenPicker';

const SOURCES = [['mine', 'From my seeds'], ['new', 'New seeds'], ['seedlings', 'Seedlings I got']];

// A row of radio pills, the same look as the "when" choice.
function Choices({id, legend, choices, value, onChange}) {
  return (
    <fieldset className="mt-4">
      <legend className="crop-picker-label step-legend">{legend}</legend>
      <div className="pill-choices">
        {choices.map(([choice, label]) => (
          <React.Fragment key={choice}>
            <input
              type="radio"
              className="visually-hidden"
              name={id}
              id={`${id}-${choice}`}
              checked={value === choice}
              onChange={() => onChange(choice)}
            />
            <label className="pill-choice" htmlFor={`${id}-${choice}`}>{label}</label>
          </React.Fragment>
        ))}
      </div>
    </fieldset>
  );
}

function errorMessages(status, data) {
  if (status === 422 && data && data.errors) {
    const messages = Object.entries(data.errors).flatMap(([field, list]) => list.map((m) => `${field.replace(/_/g, ' ')} ${m}`));
    if (messages.length > 0) return messages;
  }
  if (status === 403) return ['You can\'t sow into that garden.'];
  if (status === 401) return ['Please sign in again to sow seeds.'];
  return ['Something went wrong saving that. Please try again.'];
}

// "Sow seeds": into the nursery, or straight into a garden, from a packet of
// your own seeds, new seeds, or seedlings you were given. Sowing from a packet
// takes the seeds out of it.
export default function SowSeedsModal({nursery, gardens, seeds, onClose, onSown}) {
  const [when, setWhen] = useState('today');
  const [customDate, setCustomDate] = useState('');
  const [where, setWhere] = useState('nursery');
  const [gardenId, setGardenId] = useState(gardens.length > 0 ? String(gardens[0].id) : '');
  const [source, setSource] = useState(seeds.length > 0 ? 'mine' : 'new');
  const [search, setSearch] = useState('');
  const [seed, setSeed] = useState(null);
  const [crop, setCrop] = useState(null);
  const [quantity, setQuantity] = useState(6);
  const [saving, setSaving] = useState(false);
  const [errors, setErrors] = useState([]);
  const [sown, setSown] = useState(null);
  const [placing, setPlacing] = useState(null); // sown straight into a garden: offer to place it on the layout

  const today = localToday();
  const sownOn = {today, yesterday: daysBefore(today, 1), other: customDate}[when];
  const garden = where === 'nursery' ? nursery : gardens.find((g) => String(g.id) === gardenId);
  const cropId = source === 'mine' ? seed && seed.crop_id : crop && crop.id;
  const cropName = source === 'mine' ? seed && seed.name : crop && crop.name;
  const matching = seeds.filter((packet) => packet.name.toLowerCase().includes(search.trim().toLowerCase()));

  function chooseSource(choice) {
    setSource(choice);
    setSeed(null);
    setCrop(null);
  }

  async function save(addAnother) {
    setSaving(true);
    setErrors([]);
    try {
      const planting = {
        garden_id: garden.id,
        crop_id: cropId,
        ...(quantity > 0 ? {quantity} : {}),
        planted_from: source === 'seedlings' ? 'seedling' : 'seed',
        ...(source === 'mine' ? {parent_seed_id: seed.id} : {}),
        ...(when === 'today' ? {} : {planted_at: sownOn}),
      };
      const {ok, status, data} = await postJson('/plantings.json', {planting, ...(source === 'mine' ? {use_seeds: 1} : {})});
      if (!ok) {
        setErrors(errorMessages(status, data));
      } else if (addAnother) {
        setSown(`Sowed ${quantity} ${cropName}.`);
        setSeed(null);
        setCrop(null);
      } else if (where === 'garden') {
        setPlacing({quantity, name: cropName, garden});
      } else {
        onSown();
        return;
      }
    } catch (error) {
      setErrors(['Couldn\'t reach the server. Please try again.']);
    }
    setSaving(false);
  }

  const ready = Boolean(cropId) && Boolean(garden) && quantity > 0 && Boolean(sownOn) && sownOn <= today;
  const target = where === 'nursery' ? 'the nursery' : (garden ? garden.name : 'a garden');
  const quantityLabel = source === 'seedlings' ? 'How many seedlings?' : 'How many seeds?';

  const chooser = source === 'mine' ? (
    <>
      <label className="form-label" htmlFor="sow-seed-search">Which seeds?</label>
      <input id="sow-seed-search" className="form-control" type="search" value={search} onChange={(event) => setSearch(event.target.value)} />
      <div className="seed-packets mt-2">
        {matching.map((packet) => (
          <button
            key={packet.id}
            type="button"
            className={`seed-packet-card${seed && seed.id === packet.id ? ' selected' : ''}`}
            aria-pressed={Boolean(seed && seed.id === packet.id)}
            onClick={() => setSeed(packet)}
          >
            {packet.photo_url && <img className="seed-packet-photo" src={packet.photo_url} alt={`Photo of the ${packet.name} packet`} />}
            <span className="seed-packet-text">
              <strong>{packet.name}</strong>
              <span className="seed-packet-badges">
                {packet.heirloom === 'heirloom' && <span className="badge text-bg-success">Heirloom</span>}
                {packet.heirloom === 'hybrid' && <span className="badge text-bg-warning">Hybrid</span>}
                {packet.plant_before && packet.plant_before < sownOn && (
                  <span className="badge text-bg-warning">Expired {packet.plant_before.slice(0, 4)}</span>
                )}
              </span>
              <small>Saved {packet.saved}{packet.quantity != null ? ` · ${packet.quantity} seeds` : ''}</small>
            </span>
          </button>
        ))}
      </div>
      {matching.length === 0 && <p className="text-muted mb-0">No seed packets match. Choose &ldquo;New seeds&rdquo; to add one.</p>}
      {seed && <SeedPacket packet={seed} />}
    </>
  ) : (
    crop ? (
      <>
        <button type="button" className="btn btn-sm btn-outline-secondary mb-2" onClick={() => setCrop(null)}>Change crop</button>
        <CropDetails slug={crop.slug} />
      </>
    ) : <CropPicker id="sow-crop" label="Which crop?" onChoose={setCrop} />
  );

  if (placing) {
    return (
      <Modal title="Sow seeds" titleId="sow-seeds-title" onClose={onSown}>
        <div className="modal-body plant-dialog-body">
          <div className="alert alert-success" role="status">
            <strong>Sowed {placing.quantity} {placing.name} into {placing.garden.name}.</strong>
          </div>
          <h3 className="h5">Where in the garden did you put them?</h3>
          <p>Add it to the garden layout to remember where it is. You can do this later from the garden.</p>
          <a className="btn btn-success" href={`/gardens/${placing.garden.slug}/layout`}>Place on the garden layout</a>{' '}
          <button type="button" className="btn btn-outline-success" onClick={onSown}>Not now</button>
        </div>
      </Modal>
    );
  }

  return (
    <Modal title="Sow seeds" titleId="sow-seeds-title" size="xl" onClose={onClose}>
      <div className="modal-body plant-dialog-body sow-seeds">
        {errors.length > 0 && (
          <div className="alert alert-danger" role="alert">
            <strong>That didn&rsquo;t work.</strong>
            <ul className="mb-0">{errors.map((message) => <li key={message}>{message}</li>)}</ul>
          </div>
        )}
        {sown && <div className="alert alert-success" role="status">{sown} Sow another below.</div>}
        <div className="sow-grid">
          <div className="sow-settings">
            <WhenPicker
              id="sow-seeds"
              legend="When"
              max={today}
              when={when}
              onWhen={(choice) => { setWhen(choice); if (choice === 'other' && !customDate) setCustomDate(today); }}
              date={customDate}
              onDate={(event) => setCustomDate(event.target.value)}
              hint={sownOn > today ? 'Seeds can only be sown up to today.' : sownOn}
            />
            <Choices
              id="sow-where"
              legend="Where are you sowing them?"
              choices={[['nursery', 'Into the nursery'], ['garden', 'Straight into a garden']]}
              value={where}
              onChange={setWhere}
            />
            <p className="form-text">
              {where === 'nursery'
                ? 'They stay in the nursery as seedlings until you plant them out.'
                : 'They go in as a planting, with no nursery stage.'}
            </p>
            {where === 'garden' && (
              gardens.length > 0 ? (
                <>
                  <label className="form-label" htmlFor="sow-garden">Which garden?</label>
                  <select id="sow-garden" className="form-select" value={gardenId} onChange={(event) => setGardenId(event.target.value)}>
                    {gardens.map((g) => <option key={g.id} value={g.id}>{g.name}</option>)}
                  </select>
                </>
              ) : <p className="text-muted">You don&rsquo;t have another garden yet.</p>
            )}
            <Choices id="sow-source" legend="Where do the seeds come from?" choices={SOURCES} value={source} onChange={chooseSource} />
            <label className="form-label mt-4" htmlFor="sow-quantity">{quantityLabel}</label>
            <input
              id="sow-quantity"
              className="form-control sow-quantity"
              type="number"
              min="1"
              value={quantity}
              onChange={(event) => setQuantity(Math.max(0, parseInt(event.target.value, 10) || 0))}
            />
            {source === 'mine' && seed && seed.quantity != null && (
              <p className="form-text">That packet goes from {seed.quantity} to {Math.max(0, seed.quantity - quantity)}.</p>
            )}
          </div>
          <div className="sow-chooser">{chooser}</div>
        </div>
      </div>
      <div className="modal-footer">
        <button type="button" className="btn btn-link" onClick={onClose} disabled={saving}>Cancel</button>
        <button type="button" className="btn btn-outline-success" onClick={() => save(true)} disabled={!ready || saving}>
          Sow and add another
        </button>
        <button type="button" className="btn btn-success" onClick={() => save(false)} disabled={!ready || saving} aria-busy={saving}>
          {`Sow into ${target}`}
        </button>
      </div>
    </Modal>
  );
}
