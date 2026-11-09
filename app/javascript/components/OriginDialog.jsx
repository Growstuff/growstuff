import React, {useState} from 'react';

import Modal from './Modal';
import SaveSeedsModal from './SaveSeedsModal';

// "Step %{step} of %{total}" and the like: the server sends the sentences, with %{name} where a value goes.
export function fill(text, values) {
  return text.replace(/%\{(\w+)\}/g, (_match, name) => values[name]);
}

const capitalize = (text) => text.charAt(0).toUpperCase() + text.slice(1);

// Which step of how many each screen is. The first can't know whether it leads to two or three.
const STEPS = {how: [1, 3], seed: [2, 3], seedSource: [3, 3], seedling: [2, 2]};
const BACK = {seed: 'how', seedSource: 'seed', seedling: 'how'};

function Check() {
  return (
    <svg aria-hidden="true" width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 8.5l3.2 3L13 4.5" />
    </svg>
  );
}

// Pill buttons that pick one option, each with its picture and a tick once chosen.
function Chips({options, value, onChange}) {
  return (
    <div className="origin-chips" role="group">
      {options.map((option) => (
        <button
          key={option.value}
          type="button"
          className={`origin-chip${value === option.value ? ' on' : ''}`}
          aria-pressed={value === option.value}
          onClick={() => onChange(option.value)}
        >
          {value === option.value && <Check />}
          {option.icon_url && <img src={option.icon_url} alt="" width="28" height="28" />}
          <span>{option.label}</span>
        </button>
      ))}
    </div>
  );
}

// What they chose so far, with a way back to change it.
function Summary({pills, labels, onChange}) {
  return (
    <div className="origin-summary">
      {pills.map((pill) => <span key={pill} className="origin-pill">{pill}</span>)}
      <button type="button" className="origin-link" onClick={onChange}>{labels.change_link}</button>
    </div>
  );
}

// A packet's picture (its own photo, else the crop's icon), crop, variety and when it was saved, so the right one can be told apart.
function PacketLabel({seed}) {
  const picture = seed.photo_url || seed.icon_url;
  return (
    <span className="origin-packet-label">
      {picture && <img src={picture} alt="" className={seed.photo_url ? 'origin-packet-photo' : 'origin-packet-icon'} />}
      <span>
        <span className="origin-packet-name">{seed.name}</span>
        {seed.variety && <span className="origin-packet-variety d-block">{seed.variety}</span>}
        <span className="origin-muted d-block">{seed.detail}</span>
      </span>
    </span>
  );
}

function Packet({seed, labels, onChoose}) {
  return (
    <button type="button" className="origin-packet" onClick={() => onChoose(seed)}>
      <PacketLabel seed={seed} />
      <span className="origin-choose">{labels.choose}</span>
    </button>
  );
}

function PacketGroup({title, seeds, labels, onChoose}) {
  return (
    <div className="origin-group">
      <span className="fw-bold">{title}</span>
      {seeds.map((seed) => <Packet key={seed.id} seed={seed} labels={labels} onChoose={onChoose} />)}
    </div>
  );
}

// Their packets: those of this crop and its varieties until they type, then any of them. A packet of another crop asks first.
function SeedPicker({seeds, labels, crop, change, onChoose}) {
  const [query, setQuery] = useState('');
  const [confirming, setConfirming] = useState(null);
  const typed = query.trim().toLowerCase();
  const found = seeds.filter((seed) => !typed || seed.name.toLowerCase().includes(typed));
  const same = found.filter((seed) => seed.related);
  const others = typed ? found.filter((seed) => !seed.related) : [];

  function choose(seed) {
    if (seed.related) onChoose(seed);
    else setConfirming(seed);
  }

  if (confirming) {
    return (
      <div className="origin-confirm" role="alert">
        <p>{fill(labels.confirm_other_crop, {seed: capitalize(confirming.name), crop})}</p>
        <div className="d-flex flex-wrap gap-3">
          <button type="button" className="origin-btn origin-btn-primary" onClick={() => onChoose(confirming)}>{labels.link_anyway}</button>
          <button type="button" className="origin-btn" onClick={() => setConfirming(null)}>{labels.choose_another}</button>
        </div>
      </div>
    );
  }

  return (
    <>
      <div className="origin-field">
        <label htmlFor="origin-seed-search" className="fw-bold">{change ? labels.choose_different : labels.search}</label>
        <input
          id="origin-seed-search" className="origin-input" type="search" placeholder={labels.search_placeholder}
          value={query} onChange={(event) => setQuery(event.target.value)}
        />
        {change && <span className="origin-muted">{labels.change_hint}</span>}
      </div>
      <div className="origin-group">
        {!change && <span className="fw-bold">{fill(labels.seed_list, {crop: capitalize(crop)})}</span>}
        {!change && <span className="origin-muted">{labels.seed_list_hint}</span>}
        {same.map((seed) => <Packet key={seed.id} seed={seed} labels={labels} onChoose={choose} />)}
        {typed && same.length === 0 && <span className="origin-muted">{fill(labels.no_match, {query, crop})}</span>}
      </div>
      {others.length > 0 && <PacketGroup title={labels.other_crops} seeds={others} labels={labels} onChoose={choose} />}
    </>
  );
}

// The change dialog for a planting already linked to a packet: the packet now, a different one, or neither.
function ChangeStep({current, seeds, labels, crop, onChoose, onOtherSeeds, onAnotherWay, onRemove, onCancel}) {
  return (
    <>
      <div className="origin-field">
        <span className="origin-muted">{labels.right_now}</span>
        <div className="origin-current">
          <PacketLabel seed={current} />
          <span className="origin-linked"><Check /> {labels.linked_now}</span>
        </div>
      </div>
      <SeedPicker seeds={seeds.filter((seed) => seed.id !== current.id)} labels={labels} crop={crop} change onChoose={onChoose} />
      <div className="origin-field origin-divided">
        <span className="fw-bold">{labels.not_this_packet}</span>
        <div className="d-flex flex-wrap gap-3">
          <button type="button" className="origin-btn" onClick={onOtherSeeds}>{labels.other_seeds}</button>
          <button type="button" className="origin-btn" onClick={onAnotherWay}>{labels.another_way}</button>
        </div>
        <span className="origin-muted">{labels.other_seeds_hint}</span>
      </div>
      <div className="d-flex justify-content-between align-items-center">
        <button type="button" className="origin-link" onClick={onRemove}>{labels.remove_link}</button>
        <button type="button" className="origin-btn" onClick={onCancel}>{labels.cancel}</button>
      </div>
      <span className="origin-muted">{labels.remove_link_hint}</span>
    </>
  );
}

function KindStep({kinds, labels, onPick}) {
  return (
    <>
      <div className="origin-kinds">
        {kinds.filter((kind) => kind.main).map((kind) => (
          <button key={kind.value} type="button" className="origin-kind" onClick={() => onPick(kind.value)}>
            <img src={kind.icon_url} alt="" width="40" height="40" />
            <strong>{kind.label}</strong>
            <span className="origin-muted">{kind.hint}</span>
          </button>
        ))}
      </div>
      <div className="origin-field">
        <span className="fw-bold">{labels.other_ways}</span>
        <div className="origin-chips">
          {kinds.filter((kind) => !kind.main).map((kind) => (
            <button key={kind.value} type="button" className="origin-chip" onClick={() => onPick(kind.value)}>
              <img src={kind.icon_url} alt="" width="28" height="28" />
              <span>{kind.label}</span>
            </button>
          ))}
        </div>
      </div>
    </>
  );
}

function SeedlingStep({labels, sources, values, onChange, onSkip, kindLabel}) {
  return (
    <>
      <div className="origin-field">
        <span className="fw-bold">{labels.seedling_source_title}</span>
        <Chips options={sources} value={values.source} onChange={(source) => onChange({...values, source})} />
      </div>
      <div className="origin-panel">
        <div>
          <div className="fw-bold">{labels.label_title}</div>
          <div className="origin-muted">{labels.label_hint}</div>
        </div>
        <div className="origin-field">
          <label htmlFor="origin-supplier" className="fw-bold">{labels.supplier}</label>
          <input
            id="origin-supplier" className="origin-input" placeholder={labels.supplier_placeholder}
            value={values.supplier} onChange={(event) => onChange({...values, supplier: event.target.value})}
          />
        </div>
        <div className="origin-field">
          <label htmlFor="origin-label-text" className="fw-bold">{labels.label_text}</label>
          <textarea
            id="origin-label-text" className="origin-input" rows="3" placeholder={labels.label_text_hint}
            value={values.label_text} onChange={(event) => onChange({...values, label_text: event.target.value})}
          />
        </div>
        <div><button type="button" className="origin-link" onClick={onSkip}>{fill(labels.skip, {kind: kindLabel})}</button></div>
      </div>
    </>
  );
}

// Asks how the planting was started, a step at a time, and hands what they said to onSave as the body of the PATCH to the
// planting's origin. onSave resolves to true when it saved. A planting already linked to a packet opens on the change screen.
export default function OriginDialog({crop, cropId, kinds, seeds, currentSeed, seedSources, seedlingSources, labels, onSave, onClose}) {
  const [step, setStep] = useState(currentSeed ? 'change' : 'how');
  const [seedSource, setSeedSource] = useState(null);
  const [seedling, setSeedling] = useState({source: null, supplier: '', label_text: ''});
  const [saving, setSaving] = useState(false);
  const [failed, setFailed] = useState(false);

  async function save(planting, extra = {}) {
    setSaving(true);
    setFailed(false);
    if (!(await onSave({planting: {parent_seed_id: null, ...planting}, ...extra}))) {
      setSaving(false);
      setFailed(true);
    }
  }

  const useSeed = (seed) => save({planted_from: 'seed', parent_seed_id: seed.id});
  const saveSeedling = (details) => save({planted_from: 'seedling', ...(details && {seedling_attributes: seedling})});

  function pick(value) {
    if (value === 'seed') setStep('seed');
    else if (value === 'seedling') setStep('seedling');
    else save({planted_from: value});
  }

  const titles = {
    change: fill(labels.change_title, {crop}),
    how: fill(labels.started_title, {crop}),
    seed: labels.seed_title,
    seedSource: labels.seed_source_title,
    seedling: labels.seedling_title,
  };
  const kindLabel = (value) => kinds.find((kind) => kind.value === value).label;
  const [number, total] = STEPS[step] || [];
  const back = BACK[step];

  // Seeds that are not one of their packets get a packet made, asking what is asked of any seeds being saved.
  if (step === 'details') {
    return (
      <SaveSeedsModal
        crop={{id: cropId, name: crop}} source={seedSource} lead={[labels.step_how, labels.step_source]}
        onBack={() => setStep('seedSource')} onClose={onClose} onSaved={useSeed}
      />
    );
  }

  return (
    <Modal
      title={titles[step]} titleId="origin-dialog-title" onClose={onClose} className="origin-dialog"
      eyebrow={number && fill(labels.step, {step: number, total})}
    >
      <div className="modal-body">
        {failed && <div className="alert alert-danger" role="alert">{labels.unsaved}</div>}
        {step === 'change' && (
          <ChangeStep
            current={currentSeed} seeds={seeds} labels={labels} crop={crop} onChoose={useSeed}
            onOtherSeeds={() => setStep('seedSource')} onAnotherWay={() => setStep('how')}
            onRemove={() => save({planted_from: 'seed'})} onCancel={onClose}
          />
        )}
        {step === 'how' && <KindStep kinds={kinds} labels={labels} onPick={pick} />}
        {step === 'seed' && (
          <>
            <Summary pills={[kindLabel('seed')]} labels={labels} onChange={() => setStep('how')} />
            <SeedPicker seeds={seeds} labels={labels} crop={crop} onChoose={useSeed} />
            <div className="origin-divided d-flex flex-wrap align-items-center gap-3">
              <button type="button" className="origin-btn" onClick={() => setStep('seedSource')}>{labels.some_other_seeds}</button>
              <span className="origin-muted">{labels.some_other_seeds_hint}</span>
            </div>
          </>
        )}
        {step === 'seedSource' && (
          <>
            <Summary pills={[kindLabel('seed'), labels.not_my_packet]} labels={labels} onChange={() => setStep('seed')} />
            <div className="origin-field">
              <span className="fw-bold">{labels.seed_source_title}</span>
              <Chips options={seedSources} value={seedSource} onChange={setSeedSource} />
            </div>
          </>
        )}
        {step === 'seedling' && (
          <>
            <Summary pills={[kindLabel('seedling')]} labels={labels} onChange={() => setStep('how')} />
            <SeedlingStep
              labels={labels} sources={seedlingSources} values={seedling} onChange={setSeedling}
              kindLabel={kindLabel('seedling').toLowerCase()} onSkip={() => saveSeedling(false)}
            />
          </>
        )}
      </div>
      {step !== 'change' && (
        <div className="modal-footer">
          <button type="button" className="origin-link" onClick={onClose}>{labels.cancel}</button>
          {back && <button type="button" className="origin-btn" onClick={() => setStep(back)}>{labels.back}</button>}
          {step === 'seedSource' && (
            <button type="button" className="origin-btn origin-btn-primary" disabled={!seedSource} onClick={() => setStep('details')}>
              {labels.next}
            </button>
          )}
          {step === 'seedling' && (
            <button type="button" className="origin-btn origin-btn-primary" disabled={saving} onClick={() => saveSeedling(true)}>
              {labels.save}
            </button>
          )}
        </div>
      )}
    </Modal>
  );
}
