import React, {useEffect, useMemo, useRef, useState} from 'react';
import {createPortal} from 'react-dom';

import {getJson, patchJson} from '../api';
import PlantSomethingModal from './PlantSomethingModal';

function isPlaced(plant) {
  return plant.bed_x !== null && plant.bed_y !== null;
}

// A plant pulled off a stack has no id until the server saves it, so the client
// keeps its own key to tell circles apart in the meantime.
function keyOf(plant) {
  return plant.key || `plant-${plant.id}`;
}

function withKeys(plantings) {
  return plantings.map((planting) => ({
    ...planting,
    plants: planting.plants.map((plant) => ({...plant, key: keyOf(plant)})),
  }));
}

// The server reports per-plant errors keyed by id; any one of them explains why
// the whole arrangement was refused, since it saves all or nothing.
function firstError(data) {
  const errors = data && data.errors;
  if (!errors) return null;
  const messages = Object.values(errors).flat().filter(Boolean);
  return messages.length > 0 ? messages[0] : null;
}

function allPlants(plantings) {
  return plantings.flatMap((planting) => planting.plants.map((plant) => ({plant, planting})));
}

function clamp(value, low, high) {
  return Math.min(Math.max(value, low), high);
}

// What goes inside a plant's circle: the crop's icon.
function PlantFace({planting, labelled = false}) {
  return <img src={planting.icon_url} alt={labelled ? planting.crop_name : ''} className="garden-layout-icon" />;
}

// A copy of a composted plant that arcs from where it was dropped into the bin,
// shrinking and spinning as it goes. Drawn over the page, then removed.
function CompostGhost({ghost, onDone}) {
  const ref = useRef(null);
  useEffect(() => {
    const dx = ghost.to.x - ghost.from.x;
    const dy = ghost.to.y - ghost.from.y;
    const at = (fraction, lift) => `translate(calc(-50% + ${dx * fraction}px), calc(-50% + ${dy * fraction - lift}px))`;
    const animation = ref.current.animate([
      {transform: `${at(0, 0)} scale(1) rotate(0deg)`, opacity: 1},
      {transform: `${at(0.5, 60)} scale(0.8) rotate(100deg)`, opacity: 1, offset: 0.45},
      {transform: `${at(1, 0)} scale(0.15) rotate(240deg)`, opacity: 0.3},
    ], {duration: 600, easing: 'cubic-bezier(0.45, 0.05, 0.55, 0.95)'});
    animation.onfinish = onDone;
    return () => animation.cancel();
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <div ref={ref} className="garden-layout-compost-ghost" style={{left: ghost.from.x, top: ghost.from.y}}>
      <img src={ghost.icon} alt="" />
    </div>
  );
}

function prefersReducedMotion() {
  return Boolean(window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches);
}

// The bed, with one circle per plant. A plant's position is its centre, in grid
// cells, and it is a float: a plant goes exactly where it is dropped, and the
// grid is there to measure and line things up by, not a set of slots.
export default function GardenLayout({
  garden: initialGarden, editable, resizable, plantable, max_grid_size: maxGridSize, save_url: saveUrl,
  layout_url: layoutUrl, spade_icon_url: spadeIconUrl, compost_icon_url: compostIconUrl, plantings: initialPlantings,
}) {
  const [planting, setPlanting] = useState(false);
  // The bed's size is edited here too, and redraws as it's typed.
  const [garden, setGarden] = useState(initialGarden);
  const savedSize = useRef({columns: initialGarden.grid_columns, rows: initialGarden.grid_rows});
  const resizeTimer = useRef(null);
  const [plantings, setPlantings] = useState(() => withKeys(initialPlantings));
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState(null);
  const [notice, setNotice] = useState(null);
  const [ghosts, setGhosts] = useState([]);
  const [gulping, setGulping] = useState(false);
  const binIcon = useRef(null);
  const ghostCount = useRef(0);
  const gulpTimer = useRef(null);
  const [dragging, setDragging] = useState(null);
  const lastSaved = useRef(withKeys(initialPlantings));
  const newPlants = useRef(0);
  // The soil inside the bed's frame. Drops are measured against this, not the
  // whole bed, so a plant lands where it's let go rather than a frame's width off.
  const soilRef = useRef(null);

  const everyPlant = useMemo(() => allPlants(plantings), [plantings]);
  const onGrid = useMemo(() => everyPlant.filter(({plant}) => isPlaced(plant)), [everyPlant]);

  function placementsOf(list) {
    return allPlants(list)
      .filter(({plant}) => isPlaced(plant))
      .map(({plant, planting}) => (plant.id === null || plant.id === undefined
        ? {planting_id: planting.id, bed_x: plant.bed_x, bed_y: plant.bed_y}
        : {plant_id: plant.id, bed_x: plant.bed_x, bed_y: plant.bed_y}));
  }

  // composted: ids of plants to delete outright, rather than just take off the
  // bed; the server needs telling, since a missing plant otherwise means lifted.
  async function save(next, {composted = []} = {}) {
    setPlantings(next);
    setSaving(true);
    setMessage(null);
    const {ok, data} = await patchJson(saveUrl, {placements: placementsOf(next), composted});
    setSaving(false);
    if (ok && data) {
      const saved = withKeys(data.plantings);
      lastSaved.current = saved;
      setPlantings(saved);
    } else {
      setPlantings(lastSaved.current);
      const reason = firstError(data);
      setMessage(reason
        ? `${reason[0].toUpperCase()}${reason.slice(1)}. The bed has been put back as it was.`
        : 'That change could not be saved. The bed has been put back as it was.');
    }
  }

  function withPlant(key, changes) {
    return plantings.map((planting) => ({
      ...planting,
      plants: planting.plants.map((plant) => (plant.key === key ? {...plant, ...changes} : plant)),
    }));
  }

  // Where on the bed the pointer let go, in grid cells.
  function dropPosition(event) {
    const rect = soilRef.current.getBoundingClientRect();
    const x = ((event.clientX - rect.left) / rect.width) * garden.grid_columns;
    const y = ((event.clientY - rect.top) / rect.height) * garden.grid_rows;
    return {
      x: Number(clamp(x, 0, garden.grid_columns).toFixed(3)),
      y: Number(clamp(y, 0, garden.grid_rows).toFixed(3)),
    };
  }

  function moveTo(key, x, y) {
    save(withPlant(key, {bed_x: x, bed_y: y}));
  }

  // Pulling one off a planting's stack. If the planting has a plant that isn't
  // on the bed, that one goes down; otherwise this is one more plant than it
  // had, and the server creates it.
  function placeFromStack(plantingId, x, y) {
    const planting = plantings.find((candidate) => candidate.id === plantingId);
    const spare = planting.plants.find((plant) => !isPlaced(plant));
    if (spare) {
      save(withPlant(spare.key, {bed_x: x, bed_y: y}));
      return;
    }
    newPlants.current += 1;
    const fresh = {id: null, key: `new-${newPlants.current}`, bed_x: x, bed_y: y};
    save(plantings.map((candidate) => (candidate.id === plantingId
      ? {...candidate, plants: [...candidate.plants, fresh]}
      : candidate)));
  }

  // Off the bed and back on its stack, rather than deleted: the planting still
  // has that plant, it just isn't mapped.
  function takeOffGrid(key) {
    save(withPlant(key, {bed_x: null, bed_y: null}));
  }

  // A new planting comes back from the form as a garden card, so re-read the
  // layout to get it as chips, keeping whatever is already on the bed.
  async function planted(_card, crop) {
    setPlanting(false);
    const {ok, data} = await getJson(layoutUrl);
    if (ok && data) {
      const fresh = withKeys(data.plantings);
      lastSaved.current = fresh;
      setPlantings(fresh);
      setMessage(null);
      setNotice(`Planted ${crop ? crop.name : 'something'}. Drag it onto the bed.`);
    } else {
      setMessage('Planted, but the layout could not be refreshed. Reload the page to see it.');
    }
  }

  // Lifts every plant back onto its stack. The plants themselves stay, so the
  // plantings keep their counts; only the arrangement goes, hence the check.
  function clearBed() {
    // eslint-disable-next-line no-alert
    if (!window.confirm(`Take all ${onGrid.length} plants off the bed? Their positions will be lost.`)) return;

    save(plantings.map((planting) => ({
      ...planting,
      plants: planting.plants.map((plant) => ({...plant, bed_x: null, bed_y: null})),
    })));
  }

  // The furthest any placed plant sits, so the bed can't shrink out from under it.
  function reach() {
    return onGrid.reduce((far, {plant}) => ({
      columns: Math.max(far.columns, plant.bed_x), rows: Math.max(far.rows, plant.bed_y),
    }), {columns: 0, rows: 0});
  }

  // Redraws straight away, and saves once typing pauses, so each keystroke
  // isn't a request. A shrink that would strand a plant is refused up front,
  // where it can say which way it's blocked, rather than after a round trip.
  function resize(dimension, value) {
    const size = Math.round(Number(value));
    if (!Number.isFinite(size) || size < 1 || size > maxGridSize) return;

    const far = reach();
    if (size < far[dimension]) {
      setMessage(`The bed can't be that small: there are plants out to ${dimension === 'columns' ? 'column' : 'row'} ${Math.ceil(far[dimension])}. Move them in first.`);
      return;
    }
    setMessage(null);
    const next = {...garden, [dimension === 'columns' ? 'grid_columns' : 'grid_rows']: size};
    setGarden(next);
    clearTimeout(resizeTimer.current);
    resizeTimer.current = setTimeout(() => saveSize(next), 600);
  }

  async function saveSize(next) {
    setSaving(true);
    const {ok, data} = await patchJson(next.url, {garden: {grid_columns: next.grid_columns, grid_rows: next.grid_rows}});
    setSaving(false);
    if (ok) {
      savedSize.current = {columns: next.grid_columns, rows: next.grid_rows};
    } else {
      setGarden((current) => ({
        ...current, grid_columns: savedSize.current.columns, grid_rows: savedSize.current.rows,
      }));
      setMessage(`${firstError(data) || 'The new size could not be saved'}. The bed is back to its old size.`);
    }
  }

  // Starts a plant's flight from the pointer to the middle of the bin's icon.
  function throwInBin(event, planting) {
    if (prefersReducedMotion() || !binIcon.current) return;

    const bin = binIcon.current.getBoundingClientRect();
    ghostCount.current += 1;
    setGhosts((current) => [...current, {
      id: ghostCount.current,
      icon: planting.icon_url,
      from: {x: event.clientX, y: event.clientY},
      to: {x: bin.left + (bin.width / 2), y: bin.top + (bin.height / 2)},
    }]);
  }

  // The plant has landed: clear its copy away and let the bin swallow.
  function landed(id) {
    setGhosts((current) => current.filter((ghost) => ghost.id !== id));
    setGulping(true);
    clearTimeout(gulpTimer.current);
    gulpTimer.current = setTimeout(() => setGulping(false), 450);
  }

  // Into the compost: that plant is gone, and its planting has one fewer. A
  // plant dragged out of a stack but not yet saved just disappears.
  function compost(key, event) {
    const entry = everyPlant.find(({plant}) => plant.key === key);
    if (!entry) return;

    throwInBin(event, entry.planting);
    setNotice(`Composted a ${entry.planting.crop_name}.`);
    save(
      plantings.map((planting) => ({...planting, plants: planting.plants.filter((plant) => plant.key !== key)})),
      {composted: entry.plant.id === null || entry.plant.id === undefined ? [] : [entry.plant.id]},
    );
  }

  function dragData(event) {
    const [kind, value] = (event.dataTransfer.getData('text/plain') || '').split(':');
    return {kind, value};
  }

  function dragProps(payload) {
    if (!editable) return {};
    return {
      draggable: true,
      onDragStart: (event) => {
        event.dataTransfer.setData('text/plain', payload);
        event.dataTransfer.effectAllowed = 'move';
        setDragging(payload);
      },
      onDragEnd: () => setDragging(null),
    };
  }

  function dropOnBed(event) {
    event.preventDefault();
    const {kind, value} = dragData(event);
    const {x, y} = dropPosition(event);
    if (kind === 'stack') placeFromStack(Number(value), x, y);
    if (kind === 'plant') moveTo(value, x, y);
  }

  // The page gives the bin a slot of its own, under "About this garden", so it
  // stays in view; it's drawn there through a portal so it keeps this state.
  const [compostSlot, setCompostSlot] = useState(null);
  useEffect(() => setCompostSlot(document.getElementById('garden-layout-compost')), []);

  const compostBin = (
    <div
      className={[
        'garden-layout-compost',
        dragging && dragging.startsWith('plant:') ? 'is-ready' : '',
        gulping ? 'is-gulping' : '',
      ].filter(Boolean).join(' ')}
      onDragOver={(event) => event.preventDefault()}
      onDrop={(event) => {
        event.preventDefault();
        // Without a slot on the page the bin sits inside the sidebar, whose own
        // drop lifts a plant back onto its stack; this one must not do both.
        event.stopPropagation();
        const {kind, value} = dragData(event);
        if (kind === 'plant') compost(value, event);
      }}
    >
      <img src={compostIconUrl} alt="" className="garden-layout-compost-icon" ref={binIcon} />
      <span>
        <strong>Compost bin</strong>
        <small>Drop a plant here to remove it from its planting.</small>
      </span>
    </div>
  );

  const cells = [];
  for (let i = 0; i < garden.grid_rows * garden.grid_columns; i += 1) {
    cells.push(<div key={i} className="garden-layout-cell" />);
  }

  return (
    <div className="garden-layout">
      {message && <div className="alert alert-warning garden-layout-message">{message}</div>}
      {notice && !message && <div className="alert alert-success garden-layout-message" role="status">{notice}</div>}

      <div className="garden-layout-columns">
        <div className="garden-layout-grid-wrapper">
          <div className="garden-layout-controls">
            {resizable && (
              <div className="garden-layout-size">
                <label>
                  Columns
                  <input
                    type="number" min="1" max={maxGridSize} className="form-control form-control-sm"
                    value={garden.grid_columns} onChange={(event) => resize('columns', event.target.value)}
                  />
                </label>
                <span aria-hidden="true">×</span>
                <label>
                  Rows
                  <input
                    type="number" min="1" max={maxGridSize} className="form-control form-control-sm"
                    value={garden.grid_rows} onChange={(event) => resize('rows', event.target.value)}
                  />
                </label>
              </div>
            )}
            {editable && onGrid.length > 0 && (
              <button type="button" className="btn btn-sm btn-outline-danger garden-layout-clear" onClick={clearBed}>
                Remove all
              </button>
            )}
          </div>
          <div
            className="garden-layout-grid"
            // As big as fits: the full width available, unless that would make
            // the bed taller than the window, in which case the height decides.
            style={{
              aspectRatio: `${garden.grid_columns} / ${garden.grid_rows}`,
              width: `min(100%, calc((100vh - 14rem) * ${garden.grid_columns / garden.grid_rows}))`,
            }}
            onDragOver={editable ? (event) => event.preventDefault() : undefined}
            onDrop={editable ? dropOnBed : undefined}
          >
            <div
              className="garden-layout-cells"
              ref={soilRef}
              style={{
                gridTemplateColumns: `repeat(${garden.grid_columns}, 1fr)`,
                gridTemplateRows: `repeat(${garden.grid_rows}, 1fr)`,
              }}
            >
              {cells}
            </div>
            {onGrid.map(({plant, planting}) => (
              <div
                key={plant.key}
                className={`garden-layout-plant${dragging === `plant:${plant.key}` ? ' is-dragging' : ''}`}
                style={{
                  left: `${(plant.bed_x / garden.grid_columns) * 100}%`,
                  top: `${(plant.bed_y / garden.grid_rows) * 100}%`,
                  width: `${100 / garden.grid_columns}%`,
                }}
                title={`${planting.crop_name} at ${plant.bed_x}, ${plant.bed_y}`}
                {...dragProps(`plant:${plant.key}`)}
              >
                <a href={planting.url} className="garden-layout-plant-circle">
                  <PlantFace planting={planting} labelled />
                </a>
              </div>
            ))}
          </div>
        </div>

        <aside
          className="garden-layout-tray"
          onDragOver={editable ? (event) => event.preventDefault() : undefined}
          onDrop={editable ? (event) => {
            event.preventDefault();
            const {kind, value} = dragData(event);
            if (kind === 'plant') takeOffGrid(value);
          } : undefined}
        >
          <h3 className="garden-layout-tray-heading">
            Plants
            {saving && <span className="garden-layout-saving"> — saving…</span>}
          </h3>
          {plantable && (
            <button type="button" className="btn btn-success btn-sm garden-layout-plant-button" onClick={() => setPlanting(true)}>
              <i className="fa fa-plus" aria-hidden="true" /> Plant something
            </button>
          )}
          {plantings.length === 0 ? (
            <p className="garden-layout-tray-empty">Nothing is growing here yet.</p>
          ) : (
            <ul className="garden-layout-tray-list">
              {plantings.map((planting) => {
                const waiting = planting.plants.filter((plant) => !isPlaced(plant)).length;
                return (
                  <li key={planting.id}>
                    {/* The planting's crop chip, as on the garden cards. Dragging it
                        puts one more of that crop on the bed; it stays here, so
                        it can be dragged again. */}
                    {editable ? (
                      <div
                        className={`chip crop-chip garden-layout-chip${dragging === `stack:${planting.id}` ? ' is-dragging' : ''}`}
                        title={`Drag onto the bed to place a ${planting.crop_name}`}
                        {...dragProps(`stack:${planting.id}`)}
                      >
                        <img className="crop-icon" src={planting.icon_url} alt="" />
                        {planting.crop_name}
                        {waiting > 0 && <span className="garden-layout-chip-count">{waiting}</span>}
                      </div>
                    ) : (
                      <a href={planting.url} className="chip crop-chip garden-layout-chip">
                        <img className="crop-icon" src={planting.icon_url} alt="" />
                        {planting.crop_name}
                      </a>
                    )}
                  </li>
                );
              })}
            </ul>
          )}
          {planting && (
            <PlantSomethingModal
              garden={garden}
              iconUrl={spadeIconUrl}
              onClose={() => setPlanting(false)}
              onCreated={planted}
            />
          )}
          {editable && !compostSlot && compostBin}
          {editable && <p className="garden-layout-hint">Drag a crop onto the bed, or a plant back here to lift it.</p>}
        </aside>
      </div>
      {editable && compostSlot && createPortal(compostBin, compostSlot)}
      {ghosts.length > 0 && createPortal(
        ghosts.map((ghost) => <CompostGhost key={ghost.id} ghost={ghost} onDone={() => landed(ghost.id)} />),
        document.body,
      )}
    </div>
  );
}
