import React, {useState} from 'react';

import StarRating from './StarRating';
import {patchJson} from '../api';

// The rating fact card, for someone who may edit the planting: click a star to
// rate it. StarRating is a real radio group underneath, so the arrow keys and
// screen readers work; this just saves what it reports.
//
// The new rating shows immediately and goes back if the save fails, so a
// click always feels answered.
export default function PlantingRating({planting, value}) {
  const [rating, setRating] = useState(value ?? null);
  const [error, setError] = useState(null);

  async function change(next) {
    const previous = rating;
    setRating(next);
    setError(null);
    const {ok} = await patchJson(planting.url, {planting: {overall_rating: next}});
    if (!ok) {
      setRating(previous);
      setError("Couldn't save that rating.");
    }
  }

  return (
    <div className="planting-rating">
      <StarRating id={`planting-rating-${planting.id}`} label="Rating" value={rating} onChange={change} />
      {error && <p className="text-danger small mb-0" role="alert">{error}</p>}
    </div>
  );
}
