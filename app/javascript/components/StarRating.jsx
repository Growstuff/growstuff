import React, {useState} from 'react';

const STARS = [1, 2, 3, 4, 5];
const WORDS = {1: 'Poor', 5: 'Great'};

// A rating out of five as stars. They are real radio buttons underneath, so
// the arrow keys and screen readers work as they do for any radio group; the
// stars just light up as far as the one hovered, or chosen. `value` is a number
// from 1 to 5, or null for no rating, and Clear puts it back to that.
export default function StarRating({id, label, value, onChange}) {
  const [hovered, setHovered] = useState(null);
  const lit = hovered ?? value ?? 0;

  return (
    <fieldset className="star-rating">
      <legend className="form-label">{label}</legend>
      <div className="star-rating-stars" onMouseLeave={() => setHovered(null)}>
        {STARS.map((number) => (
          <React.Fragment key={number}>
            <input
              type="radio"
              className="visually-hidden"
              id={`${id}-${number}`}
              name={id}
              checked={value === number}
              onChange={() => onChange(number)}
            />
            <label
              htmlFor={`${id}-${number}`}
              className={`star-rating-star${number <= lit ? ' star-rating-star--lit' : ''}`}
              title={WORDS[number] ? `${number} – ${WORDS[number]}` : `${number} of 5`}
              onMouseEnter={() => setHovered(number)}
            >
              <i className={`${number <= lit ? 'fas' : 'far'} fa-star`} aria-hidden="true" />
              <span className="visually-hidden">{number} of 5{WORDS[number] ? `, ${WORDS[number]}` : ''}</span>
            </label>
          </React.Fragment>
        ))}
        <span className="star-rating-value">{value ? `${value} of 5` : 'Not rated'}</span>
        {value && (
          <button type="button" className="btn btn-sm btn-link" onClick={() => onChange(null)}>Clear</button>
        )}
      </div>
    </fieldset>
  );
}
