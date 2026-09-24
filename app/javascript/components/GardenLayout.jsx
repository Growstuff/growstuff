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

// "3 Mar", for telling apart plantings of the same crop.
function plantedLabel(planting) {
  if (!planting.planted_at) return null;
  const date = new Date(`${planting.planted_at}T00:00:00`);
  return Number.isNaN(date.getTime()) ? null : date.toLocaleDateString(undefined, {day: 'numeric', month: 'short'});
}

// How many cells across a plant is drawn: its own size if it has been resized,
// otherwise its crop's default.
function diameterOf(plant, planting) {
  return plant.diameter ?? planting.default_diameter ?? 1;
}

// Everything besides plants that can go on the bed, in the order the sidebar
// offers them, and how each is drawn. A point is an object with a size, centred
// on (x, y); a label is text at (x, y); a line runs from (x, y) to (x2, y2); an
// area is the rectangle with those two corners. Lines and areas share their
// handles: drag the middle to move, the ends or corners to reshape.
const FEATURE_TYPES = {
  stone: {name: 'Stepping stone', shape: 'point', size: 0.8},
  sprinkler: {name: 'Sprinkler', shape: 'point', size: 0.7},
  tap: {name: 'Tap', shape: 'point', size: 0.6},
  stake: {name: 'Stake', shape: 'point', size: 0.3},
  label: {name: 'Label', shape: 'label', faIcon: 'fa-font'},
  row: {name: 'Row', shape: 'line', faIcon: 'fa-grip-lines'},
  path: {name: 'Path', shape: 'line', faIcon: 'fa-shoe-prints'},
  dripline: {name: 'Drip line', shape: 'line', faIcon: 'fa-tint'},
  fence: {name: 'Fence', shape: 'line', faIcon: 'fa-grip-lines-vertical'},
  trellis: {name: 'Trellis', shape: 'line', faIcon: 'fa-border-all'},
  netting: {name: 'Netting', shape: 'area', faIcon: 'fa-th'},
};

// How the features are grouped in the toolbar above the bed.
const FEATURE_GROUPS = [
  {name: 'Ground', kinds: ['stone', 'path']},
  {name: 'Water', kinds: ['sprinkler', 'tap', 'dripline']},
  {name: 'Supports', kinds: ['stake', 'fence', 'trellis', 'netting']},
  {name: 'Markers', kinds: ['label', 'row']},
];

function shapeOf(feature) {
  return FEATURE_TYPES[feature.kind]?.shape;
}

// Lines and areas: the kinds with two points, moved by their middle.
function isSpan(feature) {
  return ['line', 'area'].includes(shapeOf(feature));
}

// How big a feature is, for keeping it on the bed; labels and the ends of
// lines and areas are points.
function featureSize(feature) {
  return FEATURE_TYPES[feature.kind]?.size || 0;
}

function featureName(kind) {
  return FEATURE_TYPES[kind].name.toLowerCase();
}

function round3(value) {
  return Number(value.toFixed(3));
}

// A line or area as it would be with one end or corner dragged elsewhere.
function withEnd(row, end, x, y) {
  return end === 'start' ? {...row, x, y} : {...row, x2: x, y2: y};
}

// Ring colours for telling apart plantings drawn with the same icon: the five
// hues that stay distinguishable from each other on the soil, colour blind or
// not (checked against the soil for every pair, as any two plantings can end up
// side by side). Always given out in this order.
const RING_COLOURS = ['#2a78d6', '#1baf7a', '#c98500', '#008300', '#e34948'];

// planting id => ring colour. Only plantings that share their icon with another
// get one, in the order they were made, so a planting keeps its colour as
// others come and go. Past five in a group there's no colour left; those go by
// their names.
function ringColours(plantings) {
  const groups = {};
  plantings.forEach((planting) => {
    (groups[planting.icon_key] ||= []).push(planting);
  });
  const colours = {};
  Object.values(groups).filter((group) => group.length > 1).forEach((group) => {
    [...group].sort((a, b) => a.id - b.id).forEach((planting, i) => {
      if (i < RING_COLOURS.length) colours[planting.id] = RING_COLOURS[i];
    });
  });
  return colours;
}

function clamp(value, low, high) {
  return Math.min(Math.max(value, low), high);
}

// Keeps every plant wholly on the bed. A position is the plant's centre, so it
// has to stay half the plant's width from each edge, or a big plant near the
// edge hangs over the frame. A plant wider than the bed sits in the middle.
function fitPlants(plantings, garden) {
  return plantings.map((planting) => ({
    ...planting,
    plants: planting.plants.map((plant) => {
      if (!isPlaced(plant)) return plant;
      const radius = Math.min(diameterOf(plant, planting), garden.grid_columns, garden.grid_rows) / 2;
      return {
        ...plant,
        bed_x: Number(clamp(plant.bed_x, radius, garden.grid_columns - radius).toFixed(3)),
        bed_y: Number(clamp(plant.bed_y, radius, garden.grid_rows - radius).toFixed(3)),
      };
    }),
  }));
}

// What goes inside a plant's circle: the crop's icon.
function PlantFace({planting, labelled = false}) {
  return <img src={planting.icon_url} alt={labelled ? planting.crop_name : ''} className="garden-layout-icon" />;
}

// Swapped in for the browser's own drag picture, which is a faint snapshot that
// all but vanishes on dark soil; the layout draws its own instead. Made once,
// up front, as setDragImage needs an image that has already loaded.
const invisibleDragImage = (() => {
  if (typeof Image === 'undefined') return null;
  const image = new Image();
  image.src = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7';
  return image;
})();

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
  garden: initialGarden, editable, resizable, plantable, max_grid_size: maxGridSize, max_diameter: maxDiameter,
  save_url: saveUrl,
  layout_url: layoutUrl, spade_icon_url: spadeIconUrl, compost_icon_url: compostIconUrl, plantings: initialPlantings,
  features: initialFeatures = [], feature_icon_urls: featureIcons = {},
}) {
  const [planting, setPlanting] = useState(false);
  // The bed's size is edited here too, and redraws as it's typed.
  const [garden, setGarden] = useState(initialGarden);
  const savedSize = useRef({columns: initialGarden.grid_columns, rows: initialGarden.grid_rows});
  const resizeTimer = useRef(null);
  const [plantings, setPlantings] = useState(() => fitPlants(withKeys(initialPlantings), initialGarden));
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState(null);
  const [notice, setNotice] = useState(null);
  const [ghosts, setGhosts] = useState([]);
  const [gulping, setGulping] = useState(false);
  const binIcon = useRef(null);
  const ghostCount = useRef(0);
  const gulpTimer = useRef(null);
  const [dragging, setDragging] = useState(null);
  const lastSaved = useRef(fitPlants(withKeys(initialPlantings), initialGarden));
  const newPlants = useRef(0);
  // The soil inside the bed's frame. Drops are measured against this, not the
  // whole bed, so a plant lands where it's let go rather than a frame's width off.
  const soilRef = useRef(null);
  // A resize in progress: which plant, where its centre is on screen, and how
  // big a cell is, so the pointer's distance from the centre gives a diameter.
  const resizing = useRef(null);
  const [liveSize, setLiveSize] = useState(null); // {key, diameter} while dragging the handle
  // What follows the pointer while a plant is dragged: {icon, size, x, y} in px.
  const [avatar, setAvatar] = useState(null);
  // Stepping stones, labels and rows: saved with the plants, in the same request.
  const [features, setFeatures] = useState(initialFeatures);
  const lastSavedFeatures = useRef(initialFeatures);
  const featureCount = useRef(0);
  // A line's end or an area's corner being dragged, and where it is so far.
  const endDragged = useRef(null);
  // The bed's edge being dragged, and the size it would be so far.
  const bedDrag = useRef(null);
  const [liveBed, setLiveBed] = useState(null);
  const [liveEnd, setLiveEnd] = useState(null);
  // The size last given to a plant of each planting, by planting id, so the
  // next one taken off its chip matches: shrink a chive and the next is as small.
  const nextSizes = useRef({});

  const everyPlant = useMemo(() => allPlants(plantings), [plantings]);
  const onGrid = useMemo(() => everyPlant.filter(({plant}) => isPlaced(plant)), [everyPlant]);
  const colours = useMemo(() => ringColours(plantings), [plantings]);
  // The planting being pointed at, on the bed or in the sidebar, whose plants
  // are picked out and the rest faded.
  const [hovered, setHovered] = useState(null);
  // How wide a cell is on screen, to know which plants have room for a name.
  const [cellPx, setCellPx] = useState(0);
  useEffect(() => {
    const soil = soilRef.current;
    if (!soil || typeof ResizeObserver === 'undefined') return undefined;
    const measure = () => setCellPx(soil.getBoundingClientRect().width / garden.grid_columns);
    measure();
    const observer = new ResizeObserver(measure);
    observer.observe(soil);
    return () => observer.disconnect();
  }, [garden.grid_columns]);

  function placementsOf(list) {
    return allPlants(list)
      .filter(({plant}) => isPlaced(plant))
      .map(({plant, planting}) => {
        const where = {bed_x: plant.bed_x, bed_y: plant.bed_y, diameter: plant.diameter ?? null};
        return plant.id === null || plant.id === undefined
          ? {planting_id: planting.id, ...where}
          : {plant_id: plant.id, ...where};
      });
  }

  // composted: ids of plants to delete outright, rather than just take off the
  // bed; the server needs telling, since a missing plant otherwise means lifted.
  // nextFeatures: the stones, labels and rows to save along with the plants.
  async function save(unfitted, {composted = [], nextFeatures = features} = {}) {
    const next = fitPlants(unfitted, garden);
    setPlantings(next);
    setFeatures(nextFeatures);
    setSaving(true);
    setMessage(null);
    const {ok, data} = await patchJson(saveUrl, {placements: placementsOf(next), composted, features: nextFeatures});
    setSaving(false);
    if (ok && data) {
      const saved = fitPlants(withKeys(data.plantings), garden);
      lastSaved.current = saved;
      setPlantings(saved);
      lastSavedFeatures.current = data.features || [];
      setFeatures(lastSavedFeatures.current);
    } else {
      setPlantings(lastSaved.current);
      setFeatures(lastSavedFeatures.current);
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

  // What the next plant off this planting's chip should be: the size last set
  // on one of its plants here, or after a reload its newest plant that has a
  // size of its own. Null means follow the crop's default.
  function sizeForNext(planting) {
    const remembered = nextSizes.current[planting.id];
    if (remembered !== undefined) return remembered;

    const sized = planting.plants
      .filter((plant) => plant.id !== null && plant.id !== undefined && plant.diameter !== null && plant.diameter !== undefined)
      .sort((a, b) => b.id - a.id)[0];
    return sized ? sized.diameter : null;
  }

  function moveTo(key, x, y) {
    save(withPlant(key, {bed_x: x, bed_y: y}));
  }

  // Pulling one off a planting's stack. If the planting has a plant that isn't
  // on the bed, that one goes down; otherwise this is one more plant than it
  // had, and the server creates it.
  function placeFromStack(plantingId, x, y) {
    const planting = plantings.find((candidate) => candidate.id === plantingId);
    const size = sizeForNext(planting);
    const spare = planting.plants.find((plant) => !isPlaced(plant));
    if (spare) {
      save(withPlant(spare.key, {bed_x: x, bed_y: y, diameter: size ?? spare.diameter ?? null}));
      return;
    }
    newPlants.current += 1;
    const fresh = {id: null, key: `new-${newPlants.current}`, bed_x: x, bed_y: y, diameter: size};
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
      const fresh = fitPlants(withKeys(data.plantings), garden);
      lastSaved.current = fresh;
      setPlantings(fresh);
      lastSavedFeatures.current = data.features || [];
      setFeatures(lastSavedFeatures.current);
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
    if (!window.confirm(`Take all ${onGrid.length} plants off the bed? Their positions will be lost. `
      + 'Stones, lines, netting and the rest stay where they are.')) return;

    save(plantings.map((planting) => ({
      ...planting,
      plants: planting.plants.map((plant) => ({...plant, bed_x: null, bed_y: null})),
    })));
  }

  // How far out the placed plants reach, edges and all, so the bed can't
  // shrink out from under one.
  function reach() {
    const plantsReach = onGrid.reduce((far, {plant, planting}) => {
      const radius = diameterOf(plant, planting) / 2;
      return {
        columns: Math.max(far.columns, plant.bed_x + radius), rows: Math.max(far.rows, plant.bed_y + radius),
      };
    }, {columns: 0, rows: 0});
    return features.reduce((far, feature) => {
      const margin = featureSize(feature) / 2;
      return {
        columns: Math.max(far.columns, feature.x + margin, feature.x2 ?? 0),
        rows: Math.max(far.rows, feature.y + margin, feature.y2 ?? 0),
      };
    }, plantsReach);
  }

  // Redraws straight away, and saves once changes pause, so each keystroke
  // isn't a request. A shrink that would strand something on the bed is refused
  // up front, where it can say which way it's blocked, rather than after a
  // round trip.
  function setBedSize(columns, rows) {
    const far = reach();
    let blocked = null;
    if (columns < far.columns) blocked = 'columns';
    else if (rows < far.rows) blocked = 'rows';
    if (blocked) {
      setMessage(`The bed can't be that small: there are things out to ${blocked === 'columns' ? 'column' : 'row'} ${Math.ceil(far[blocked])}. Move them in first.`);
      return;
    }
    setMessage(null);
    const next = {...garden, grid_columns: columns, grid_rows: rows};
    setGarden(next);
    clearTimeout(resizeTimer.current);
    resizeTimer.current = setTimeout(() => saveSize(next), 600);
  }

  // From the Columns and Rows boxes.
  function resize(dimension, value) {
    const size = Math.round(Number(value));
    if (!Number.isFinite(size) || size < 1 || size > maxGridSize) return;

    setBedSize(dimension === 'columns' ? size : garden.grid_columns, dimension === 'rows' ? size : garden.grid_rows);
  }

  // Dragging the bed's right edge, bottom edge or corner. The pointer is
  // measured in cells as they were when the drag began, and the bed only
  // changes when it's let go: it's sized to fit the window, so redrawing it
  // mid-drag would shrink the cells under the pointer. Until then a dashed
  // outline shows the new size.
  function startBedDrag(event, edge) {
    event.preventDefault();
    event.stopPropagation();
    const rect = soilRef.current.getBoundingClientRect();
    const cell = rect.width / garden.grid_columns;
    bedDrag.current = {edge, left: rect.left, top: rect.top, cell};
    event.currentTarget.setPointerCapture(event.pointerId);
    setLiveBed({columns: garden.grid_columns, rows: garden.grid_rows, cell});
  }

  function moveBedDrag(event) {
    const current = bedDrag.current;
    if (!current) return;
    const cells = (distance) => clamp(Math.round(distance / current.cell), 1, maxGridSize);
    setLiveBed({
      columns: current.edge === 'bottom' ? garden.grid_columns : cells(event.clientX - current.left),
      rows: current.edge === 'right' ? garden.grid_rows : cells(event.clientY - current.top),
      cell: current.cell,
    });
  }

  function finishBedDrag() {
    const current = bedDrag.current;
    bedDrag.current = null;
    if (current && liveBed && (liveBed.columns !== garden.grid_columns || liveBed.rows !== garden.grid_rows)) {
      setBedSize(liveBed.columns, liveBed.rows);
    }
    setLiveBed(null);
  }

  function bedEdgeProps(edge) {
    return {
      onPointerDown: (event) => startBedDrag(event, edge),
      onPointerMove: moveBedDrag,
      onPointerUp: finishBedDrag,
      onPointerCancel: finishBedDrag,
    };
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

  // A planting's chip dropped in the bin: compost one of its plants that isn't
  // on the bed. Placed ones are left alone; to compost one of those, drag it.
  function compostSpare(plantingId, event) {
    const planting = plantings.find((candidate) => candidate.id === plantingId);
    if (!planting) return;
    const spare = planting.plants.find((plant) => !isPlaced(plant));
    if (!spare) {
      setMessage(`Every ${planting.crop_name} is on the bed. Drag the one you want to compost into the bin.`);
      return;
    }
    compost(spare.key, event);
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

  // The handle on a plant's edge: drag it out to grow the plant, in to shrink
  // it. Uses pointer events rather than drag-and-drop, which moves the plant.
  function startResize(event, plant) {
    event.preventDefault();
    event.stopPropagation();
    const rect = soilRef.current.getBoundingClientRect();
    resizing.current = {
      key: plant.key,
      cellPx: rect.width / garden.grid_columns,
      centre: {
        x: rect.left + ((plant.bed_x / garden.grid_columns) * rect.width),
        y: rect.top + ((plant.bed_y / garden.grid_rows) * rect.height),
      },
    };
    event.currentTarget.setPointerCapture(event.pointerId);
  }

  function resizeTo(event) {
    const current = resizing.current;
    if (!current) return;
    const distance = Math.hypot(event.clientX - current.centre.x, event.clientY - current.centre.y);
    // In steps of a twentieth of a cell, so sizes come out as tidy numbers.
    // No bigger than the bed, which it couldn't then fit on.
    const largest = Math.min(maxDiameter, garden.grid_columns, garden.grid_rows);
    const diameter = clamp(Math.round((2 * distance / current.cellPx) * 20) / 20, 0.25, largest);
    setLiveSize({key: current.key, diameter});
  }

  function endResize() {
    const current = resizing.current;
    resizing.current = null;
    if (liveSize && current && liveSize.key === current.key) {
      const resized = everyPlant.find(({plant}) => plant.key === current.key);
      if (resized) nextSizes.current[resized.planting.id] = liveSize.diameter;
      save(withPlant(current.key, {diameter: liveSize.diameter}));
    }
    setLiveSize(null);
  }

  // The garden features: stones, sprinklers, labels, rows, netting and the rest.
  // Each change saves the whole arrangement, as a plant does.
  function saveFeatures(nextFeatures) {
    save(plantings, {nextFeatures});
  }

  function newFeatureId() {
    featureCount.current += 1;
    return `f${Date.now().toString(36)}${featureCount.current}`;
  }

  function onBed(value, size, margin = 0) {
    return round3(clamp(value, margin, size - margin));
  }

  function askForText(question, current = '') {
    // eslint-disable-next-line no-alert
    const answer = window.prompt(question, current);
    return answer === null ? null : answer.trim().slice(0, 40);
  }

  function addFeature(kind, x, y) {
    const type = FEATURE_TYPES[kind];
    if (!type) return;
    const {grid_columns: columns, grid_rows: rows} = garden;
    const id = newFeatureId();
    if (type.shape === 'point') {
      const margin = type.size / 2;
      saveFeatures([...features, {id, kind, x: onBed(x, columns, margin), y: onBed(y, rows, margin)}]);
    } else if (type.shape === 'label') {
      const text = askForText('What should the label say?');
      if (text) saveFeatures([...features, {id, kind, x: onBed(x, columns), y: onBed(y, rows), text}]);
    } else {
      // A line two cells long, across the bed, or an area two cells square;
      // drag its ends or corners to reshape it.
      const halfX = Math.min(1, columns / 2);
      const halfY = type.shape === 'area' ? Math.min(1, rows / 2) : 0;
      const middleX = onBed(x, columns, halfX);
      const middleY = onBed(y, rows, halfY);
      saveFeatures([...features, {
        id, kind,
        x: round3(middleX - halfX), y: round3(middleY - halfY), x2: round3(middleX + halfX), y2: round3(middleY + halfY),
      }]);
    }
  }

  // Moves a point or label to (x, y). A line or area moves by its middle,
  // keeping its shape, and all of it on the bed.
  function moveFeature(id, x, y) {
    const {grid_columns: columns, grid_rows: rows} = garden;
    saveFeatures(features.map((feature) => {
      if (feature.id !== id) return feature;
      if (!isSpan(feature)) {
        const margin = featureSize(feature) / 2;
        return {...feature, x: onBed(x, columns, margin), y: onBed(y, rows, margin)};
      }
      const halfX = (feature.x2 - feature.x) / 2;
      const halfY = (feature.y2 - feature.y) / 2;
      const middleX = clamp(x, Math.abs(halfX), columns - Math.abs(halfX));
      const middleY = clamp(y, Math.abs(halfY), rows - Math.abs(halfY));
      return {
        ...feature,
        x: round3(middleX - halfX), y: round3(middleY - halfY), x2: round3(middleX + halfX), y2: round3(middleY + halfY),
      };
    }));
  }

  function removeFeature(id, event) {
    const feature = features.find((candidate) => candidate.id === id);
    if (!feature) return;
    if (featureIcons[feature.kind]) throwInBin(event, {icon_url: featureIcons[feature.kind]});
    setNotice(`Took the ${featureName(feature.kind)} off the bed.`);
    saveFeatures(features.filter((candidate) => candidate.id !== id));
  }

  // A label's text, or the name of a line or area, which they can do without.
  function rename(feature) {
    let question = `What would you like to call this ${featureName(feature.kind)}? (Leave it empty for no name.)`;
    if (feature.kind === 'row') question = 'What is growing in this row? (Leave it empty for no name.)';
    if (feature.kind === 'label') question = 'What should the label say?';
    const text = askForText(question, feature.text || '');
    if (text === null || (feature.kind === 'label' && !text)) return;
    saveFeatures(features.map((candidate) => (candidate.id === feature.id ? {...candidate, text} : candidate)));
  }

  // Dragging a line's end or an area's corner, with pointer events like the
  // plant resize handle.
  function startEndDrag(event, row, end) {
    event.preventDefault();
    event.stopPropagation();
    endDragged.current = {id: row.id, end};
    event.currentTarget.setPointerCapture(event.pointerId);
  }

  function moveEndDrag(event) {
    if (!endDragged.current) return;
    const rect = soilRef.current.getBoundingClientRect();
    const x = onBed(((event.clientX - rect.left) / rect.width) * garden.grid_columns, garden.grid_columns);
    const y = onBed(((event.clientY - rect.top) / rect.height) * garden.grid_rows, garden.grid_rows);
    setLiveEnd({...endDragged.current, x, y});
  }

  function finishEndDrag() {
    const current = endDragged.current;
    endDragged.current = null;
    if (current && liveEnd && liveEnd.id === current.id) {
      saveFeatures(features.map((feature) => (feature.id === current.id
        ? withEnd(feature, current.end, liveEnd.x, liveEnd.y)
        : feature)));
    }
    setLiveEnd(null);
  }

  // A line or area as drawn right now: with the end or corner being dragged
  // where it has got to.
  function asDrawn(row) {
    return liveEnd && liveEnd.id === row.id ? withEnd(row, liveEnd.end, liveEnd.x, liveEnd.y) : row;
  }

  function dragData(event) {
    const [kind, value] = (event.dataTransfer.getData('text/plain') || '').split(':');
    return {kind, value};
  }

  // look: the crop icon and diameter in cells, for the circle that follows the
  // pointer while it's dragged.
  function dragProps(payload, look) {
    if (!editable) return {};
    return {
      draggable: true,
      onDragStart: (event) => {
        // Pulling on a plant's resize handle resizes it; it shouldn't also
        // start dragging the plant it belongs to.
        if (resizing.current || endDragged.current || bedDrag.current) {
          event.preventDefault();
          return;
        }
        event.dataTransfer.setData('text/plain', payload);
        event.dataTransfer.effectAllowed = 'move';
        if (invisibleDragImage) event.dataTransfer.setDragImage(invisibleDragImage, 0, 0);
        const cell = soilRef.current.getBoundingClientRect().width / garden.grid_columns;
        setAvatar({
          icon: look.icon, text: look.text, size: Math.max(20, look.diameter * cell), x: event.clientX, y: event.clientY,
        });
        setDragging(payload);
      },
      onDragEnd: endDrag,
    };
  }

  function endDrag() {
    setDragging(null);
    setAvatar(null);
  }

  // Follow the pointer anywhere on the page while dragging, and tidy up when the
  // drag ends however it ends. The drag's own end event isn't enough: a plant
  // dropped in the compost is gone from the page before that event would fire.
  useEffect(() => {
    if (!avatar) return undefined;
    let frame = null;
    const follow = (event) => {
      const {clientX: x, clientY: y} = event;
      if (frame) return;
      frame = requestAnimationFrame(() => {
        frame = null;
        setAvatar((current) => (current ? {...current, x, y} : current));
      });
    };
    document.addEventListener('dragover', follow);
    document.addEventListener('drop', endDrag, true);
    document.addEventListener('dragend', endDrag, true);
    return () => {
      if (frame) cancelAnimationFrame(frame);
      document.removeEventListener('dragover', follow);
      document.removeEventListener('drop', endDrag, true);
      document.removeEventListener('dragend', endDrag, true);
    };
  }, [avatar !== null]); // eslint-disable-line react-hooks/exhaustive-deps

  function dropOnBed(event) {
    event.preventDefault();
    const {kind, value} = dragData(event);
    const {x, y} = dropPosition(event);
    if (kind === 'stack') placeFromStack(Number(value), x, y);
    if (kind === 'plant') moveTo(value, x, y);
    if (kind === 'new-feature') addFeature(value, x, y);
    if (kind === 'feature') moveFeature(value, x, y);
  }

  // The page gives the bin a slot of its own, under "About this garden", so it
  // stays in view; it's drawn there through a portal so it keeps this state.
  const [compostSlot, setCompostSlot] = useState(null);
  useEffect(() => setCompostSlot(document.getElementById('garden-layout-compost')), []);

  const compostBin = (
    <div
      className={[
        'garden-layout-compost',
        dragging ? 'is-ready' : '',
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
        if (kind === 'stack') compostSpare(Number(value), event);
        if (kind === 'feature') removeFeature(value, event);
      }}
    >
      <img src={compostIconUrl} alt="" className="garden-layout-compost-icon" ref={binIcon} />
      <span>
        <strong>Compost bin</strong>
        <small>Drop a plant or a crop here to remove one from its planting.</small>
      </span>
    </div>
  );

  // A position in cells as a percentage of the bed, for placing things on it.
  const acrossBed = (cells) => `${(cells / garden.grid_columns) * 100}%`;
  const downBed = (cells) => `${(cells / garden.grid_rows) * 100}%`;

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
                Clear bed
              </button>
            )}
          </div>
          {/* Everything besides plants, as a row of tiles to drag onto the bed,
              grouped by what it's for, each named when pointed at. */}
          {editable && (
            <div className="garden-layout-toolbar" role="group" aria-label="Garden features to drag onto the bed">
              {FEATURE_GROUPS.map((group) => (
                <div key={group.name} className="garden-layout-toolbar-group">
                  <span className="garden-layout-toolbar-caption">{group.name}</span>
                  <div className="garden-layout-toolbar-tiles">
                    {group.kinds.map((kind) => {
                      const type = FEATURE_TYPES[kind];
                      const what = kind === 'netting' ? 'netting' : `a ${featureName(kind)}`;
                      return (
                        <div
                          key={kind}
                          className={`garden-layout-tile${dragging === `new-feature:${kind}` ? ' is-dragging' : ''}`}
                          title={`${type.name}: drag onto the bed to add ${what}`}
                          aria-label={type.name}
                          {...dragProps(`new-feature:${kind}`, {icon: featureIcons[kind], text: type.name, diameter: type.size || 1})}
                        >
                          {featureIcons[kind] && <img src={featureIcons[kind]} alt="" />}
                          {!featureIcons[kind] && kind === 'stake' && <span className="garden-layout-stake-swatch" />}
                          {!featureIcons[kind] && type.faIcon && <i className={`fa ${type.faIcon}`} aria-hidden="true" />}
                        </div>
                      );
                    })}
                  </div>
                </div>
              ))}
            </div>
          )}
          <div
            className={`garden-layout-grid${hovered ? ' is-highlighting' : ''}`}
            // As big as fits: the full width available, unless that would make
            // the bed taller than the window, in which case the height decides.
            style={{
              aspectRatio: `${garden.grid_columns} / ${garden.grid_rows}`,
              width: `min(100%, calc((100vh - 14rem) * ${garden.grid_columns / garden.grid_rows}))`,
            }}
            onDragOver={editable ? (event) => event.preventDefault() : undefined}
            onDrop={editable ? dropOnBed : undefined}
          >
            {/* The bed's edges, on the frame, to drag it bigger or smaller. */}
            {resizable && (
              <>
                <span
                  className="garden-layout-bed-edge is-right"
                  role="presentation"
                  title="Drag to make the bed wider or narrower"
                  {...bedEdgeProps('right')}
                />
                <span
                  className="garden-layout-bed-edge is-bottom"
                  role="presentation"
                  title="Drag to make the bed longer or shorter"
                  {...bedEdgeProps('bottom')}
                />
                <span
                  className="garden-layout-bed-edge is-corner"
                  role="presentation"
                  title="Drag to resize the bed"
                  {...bedEdgeProps('corner')}
                />
              </>
            )}
            {liveBed && (
              <div
                className="garden-layout-bed-preview"
                style={{width: liveBed.columns * liveBed.cell, height: liveBed.rows * liveBed.cell}}
              >
                <span>{liveBed.columns} × {liveBed.rows}</span>
              </div>
            )}
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
            {/* Lines, then points, under the plants. */}
            <svg
              className="garden-layout-overlay"
              viewBox={`0 0 ${garden.grid_columns} ${garden.grid_rows}`}
              preserveAspectRatio="none"
              aria-hidden="true"
            >
              {features.filter((feature) => shapeOf(feature) === 'line').map(asDrawn).map((line) => (
                <g key={line.id} className={`garden-layout-line is-${line.kind}`}>
                  <line className="garden-layout-line-body" x1={line.x} y1={line.y} x2={line.x2} y2={line.y2} />
                  <line className="garden-layout-line-detail" x1={line.x} y1={line.y} x2={line.x2} y2={line.y2} />
                </g>
              ))}
            </svg>
            {features.filter((feature) => shapeOf(feature) === 'point').map((point) => (
              <div
                key={point.id}
                className={`garden-layout-point is-${point.kind}${dragging === `feature:${point.id}` ? ' is-dragging' : ''}`}
                style={{left: acrossBed(point.x), top: downBed(point.y), width: acrossBed(featureSize(point))}}
                title={FEATURE_TYPES[point.kind].name}
                {...dragProps(`feature:${point.id}`, {
                  icon: featureIcons[point.kind], text: FEATURE_TYPES[point.kind].name, diameter: featureSize(point),
                })}
              >
                <span className="garden-layout-point-shape">
                  {/* A stone and a stake are drawn; the rest show their icon. */}
                  {!['stone', 'stake'].includes(point.kind) && featureIcons[point.kind] && (
                    <img src={featureIcons[point.kind]} alt={FEATURE_TYPES[point.kind].name} />
                  )}
                </span>
              </div>
            ))}
            {/* Biggest first, so a small plant is drawn over a big one it sits beside. */}
            {[...onGrid]
              .sort((a, b) => diameterOf(b.plant, b.planting) - diameterOf(a.plant, a.planting))
              .map(({plant, planting}) => {
                const diameter = liveSize && liveSize.key === plant.key
                  ? liveSize.diameter
                  : diameterOf(plant, planting);
                return (
                  <div
                    key={plant.key}
                    className={[
                      'garden-layout-plant',
                      dragging === `plant:${plant.key}` ? 'is-dragging' : '',
                      liveSize && liveSize.key === plant.key ? 'is-resizing' : '',
                      hovered === planting.id ? 'is-highlighted' : '',
                    ].filter(Boolean).join(' ')}
                    style={{
                      left: `${(plant.bed_x / garden.grid_columns) * 100}%`,
                      top: `${(plant.bed_y / garden.grid_rows) * 100}%`,
                      width: `${(diameter / garden.grid_columns) * 100}%`,
                    }}
                    title={`${planting.crop_name}, ${diameter} ${diameter === 1 ? 'cell' : 'cells'} across`}
                    {...dragProps(`plant:${plant.key}`, {icon: planting.icon_url, diameter})}
                  >
                    {/* Not a link: a plant on the bed is something to pick up and
                        move, so a click shouldn't take you away to its planting. */}
                    <span
                      className={`garden-layout-plant-circle${colours[planting.id] ? ' has-ring' : ''}`}
                      style={colours[planting.id] ? {'--ring': colours[planting.id]} : undefined}
                      onMouseEnter={() => setHovered(planting.id)}
                      onMouseLeave={() => setHovered(null)}
                    >
                      <PlantFace planting={planting} labelled />
                    </span>
                    {/* Its name, when the plant is big enough on screen to carry one. */}
                    {diameter * cellPx >= 44 && (
                      <span className="garden-layout-plant-name" aria-hidden="true">{planting.crop_name}</span>
                    )}
                    {editable && (
                      <span
                        className="garden-layout-resize"
                        role="presentation"
                        title="Drag to make this plant bigger or smaller"
                        onPointerDown={(event) => startResize(event, plant)}
                        onPointerMove={resizeTo}
                        onPointerUp={endResize}
                        onPointerCancel={endResize}
                      />
                    )}
                  </div>
                );
              })}
            {/* Labels, over the plants, like markers stuck in the soil. */}
            {features.filter((feature) => feature.kind === 'label').map((label) => (
              <div
                key={label.id}
                className={`garden-layout-label${dragging === `feature:${label.id}` ? ' is-dragging' : ''}`}
                style={{left: acrossBed(label.x), top: downBed(label.y)}}
                title={editable ? 'Drag to move, double-click to change' : undefined}
                onDoubleClick={editable ? () => rename(label) : undefined}
                {...dragProps(`feature:${label.id}`, {text: label.text, diameter: 1})}
              >
                {label.text}
              </div>
            ))}
            {/* Netting, over the plants it covers. */}
            <svg
              className="garden-layout-overlay"
              viewBox={`0 0 ${garden.grid_columns} ${garden.grid_rows}`}
              preserveAspectRatio="none"
              aria-hidden="true"
            >
              <defs>
                <pattern id={`garden-layout-mesh-${garden.id}`} width="0.25" height="0.25" patternUnits="userSpaceOnUse">
                  <path className="garden-layout-netting-mesh" d="M0 0 L0.25 0.25 M0.25 0 L0 0.25" />
                </pattern>
              </defs>
              {features.filter((feature) => shapeOf(feature) === 'area').map(asDrawn).map((area) => (
                <rect
                  key={area.id}
                  className={`garden-layout-area is-${area.kind}`}
                  x={Math.min(area.x, area.x2)}
                  y={Math.min(area.y, area.y2)}
                  width={Math.abs(area.x2 - area.x)}
                  height={Math.abs(area.y2 - area.y)}
                  fill={`url(#garden-layout-mesh-${garden.id})`}
                />
              ))}
            </svg>
            {/* The handles of lines and areas, on top of everything: the middle to
                move it and show its name, the ends or corners to reshape it. */}
            {features.filter(isSpan).map(asDrawn).map((span) => {
              const name = FEATURE_TYPES[span.kind].name;
              const corner = shapeOf(span) === 'area' ? 'corner' : 'end';
              return (
                <React.Fragment key={span.id}>
                  {(editable || span.text) && (
                    <div
                      className={`garden-layout-span-grip${dragging === `feature:${span.id}` ? ' is-dragging' : ''}`}
                      style={{left: acrossBed((span.x + span.x2) / 2), top: downBed((span.y + span.y2) / 2)}}
                      title={editable ? `${name}: drag to move it, double-click to name it` : span.text}
                      onDoubleClick={editable ? () => rename(span) : undefined}
                      {...dragProps(`feature:${span.id}`, {text: span.text || name, diameter: 1})}
                    >
                      {span.text || '⋮⋮'}
                    </div>
                  )}
                  {editable && ['start', 'end'].map((end) => (
                    <span
                      key={end}
                      className="garden-layout-span-end"
                      role="presentation"
                      title={`Drag to move this ${corner}`}
                      style={{
                        left: acrossBed(end === 'start' ? span.x : span.x2),
                        top: downBed(end === 'start' ? span.y : span.y2),
                      }}
                      onPointerDown={(event) => startEndDrag(event, span, end)}
                      onPointerMove={moveEndDrag}
                      onPointerUp={finishEndDrag}
                      onPointerCancel={finishEndDrag}
                    />
                  ))}
                </React.Fragment>
              );
            })}
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
              <i className="fa fa-plus" aria-hidden="true" /> Add a planting
            </button>
          )}
          {plantings.length === 0 ? (
            <p className="garden-layout-tray-empty">Nothing is growing here yet.</p>
          ) : (
            <ul className="garden-layout-tray-list">
              {plantings.map((planting) => {
                const waiting = planting.plants.filter((plant) => !isPlaced(plant)).length;
                // Only crops that appear more than once need telling apart.
                const repeated = plantings.filter((other) => other.crop_name === planting.crop_name).length > 1;
                const when = repeated ? plantedLabel(planting) : null;
                const colour = colours[planting.id];
                const hover = {
                  onMouseEnter: () => setHovered(planting.id),
                  onMouseLeave: () => setHovered(null),
                };
                const highlighted = hovered === planting.id ? ' is-highlighted' : '';
                const label = (
                  <>
                    {/* The same colour as its plants' rings, so the sidebar is the key. */}
                    {colour && <span className="garden-layout-chip-colour" style={{background: colour}} />}
                    <img className="crop-icon" src={planting.icon_url} alt="" />
                    <span className="garden-layout-chip-name">
                      {planting.crop_name}
                      {when && <span className="garden-layout-chip-when"> · {when}</span>}
                    </span>
                  </>
                );
                return (
                  <li key={planting.id}>
                    {/* The planting's crop chip, as on the garden cards. Dragging it
                        puts one more of that crop on the bed; it stays here, so
                        it can be dragged again. */}
                    {editable ? (
                      <div
                        className={`chip crop-chip garden-layout-chip${dragging === `stack:${planting.id}` ? ' is-dragging' : ''}${highlighted}`}
                        title={`Drag onto the bed to place a ${planting.crop_name}`}
                        {...dragProps(`stack:${planting.id}`, {icon: planting.icon_url, diameter: sizeForNext(planting) ?? planting.default_diameter ?? 1})}
                        {...hover}
                      >
                        {label}
                        {waiting > 0 && <span className="garden-layout-chip-count">{waiting}</span>}
                      </div>
                    ) : (
                      <a href={planting.url} className={`chip crop-chip garden-layout-chip${highlighted}`} {...hover}>
                        {label}
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
          {editable && <p className="garden-layout-hint">Drag a crop onto the bed, or a plant back here to lift it. Garden features are above the bed; double-click a label, line or netting to rename it.</p>}
        </aside>
      </div>
      {editable && compostSlot && createPortal(compostBin, compostSlot)}
      {avatar && createPortal(
        <div
          className="garden-layout-drag-avatar"
          style={{left: avatar.x, top: avatar.y, width: avatar.size, height: avatar.size}}
        >
          {avatar.icon
            ? <img src={avatar.icon} alt="" />
            : <span className="garden-layout-drag-avatar-text">{avatar.text}</span>}
        </div>,
        document.body,
      )}
      {ghosts.length > 0 && createPortal(
        ghosts.map((ghost) => <CompostGhost key={ghost.id} ghost={ghost} onDone={() => landed(ghost.id)} />),
        document.body,
      )}
    </div>
  );
}
