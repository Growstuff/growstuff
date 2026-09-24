import React, {useState} from 'react';

import StarRating from './StarRating';
import {patchJson} from '../api';

// The rating fact card, for someone who may edit the planting: click a star to
// rate it. StarRating is a real radio group underneath, so the arrow keys and
// screen readers work; this only saves what it reports.
//
// The new rating shows straight away and goes back if the save fails, so a
// click always feels answered.
export default function PlantingRating({planting, value}) {
  const [rating, setRating] = useState(value ?? null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);

  async function change(next) {
    if (saving) return; // one save at a time, so a double click can't race itself

    const previous = rating;
    setRating(next);
    setSaving(true);
    setError(null);

    const {ok} = await patchJson(planting.url, {planting: {overall_rating: next}});

    setSaving(false);
    if (!ok) {
      setRating(previous);
      setError('That rating didn’t save.');
    }
  }

  return (
    <div className="planting-rating">
      <StarRating id={`planting-rating-${planting.id}`} label="Rating" value={rating} onChange={change} />
      {error && <p className="text-danger small mb-0" role="alert">{error}</p>}
    </div>
  );
}
