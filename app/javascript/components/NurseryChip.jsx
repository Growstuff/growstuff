import React from 'react';

import PlantingChip from './PlantingChip';

// One batch in the nursery: the same chip, with its menu, as a planting on a
// garden card, then how many there are. In edit mode `pick` adds a tick for
// planting it out; the tick is a plain checkbox in the nursery's form.
export default function NurseryChip({planting, defaultIconUrl, detail, pick}) {
  return (
    <>
      {pick && (
        <input
          type="checkbox"
          name="batch_ids[]"
          value={planting.id}
          id={`pick_${planting.id}`}
          className="nursery-pick-box"
          aria-label={`Plant out ${planting.crop.name}`}
        />
      )}
      <PlantingChip planting={planting} defaultIconUrl={defaultIconUrl} handlers={{}} />
      {detail && <small className="nursery-chip-detail">{detail}</small>}
    </>
  );
}
