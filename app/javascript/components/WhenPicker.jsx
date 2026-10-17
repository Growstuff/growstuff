import React from 'react';

import {formatDate} from '../dates';

export const WHEN_CHOICES = [['today', 'Today'], ['yesterday', 'Yesterday'], ['other', 'Enter date']];

// Today, Yesterday or Enter date, as pills with a date box under Enter date.
// `when` is today, yesterday or other; `date` is the date typed under other.
// `choices` can leave out Yesterday; `min` is the earliest date the box takes.
// `hint` is the date the current choice means, shown under the pills.
export default function WhenPicker({id, legend, when, onWhen, date, onDate, choices = WHEN_CHOICES, min, max, hint}) {
  return (
    <fieldset>
      <legend className="crop-picker-label step-legend">{legend}</legend>
      <div className="pill-choices">
        {choices.map(([choice, label]) => (
          <React.Fragment key={choice}>
            <input
              type="radio"
              className="visually-hidden"
              name={`${id}-when`}
              id={`${id}-when-${choice}`}
              checked={when === choice}
              onChange={() => onWhen(choice)}
              autoFocus={choice === 'today'}
            />
            <label className="pill-choice" htmlFor={`${id}-when-${choice}`}>{label}</label>
          </React.Fragment>
        ))}
      </div>
      {when === 'other' ? (
        <div className="mt-3">
          <label className="form-label" htmlFor={`${id}-date`}>Date</label>
          <input
            id={`${id}-date`}
            type="date"
            className="form-control when-date"
            value={date}
            min={min}
            max={max}
            onChange={onDate}
            required
            autoFocus
          />
        </div>
      ) : (
        <p className="step-hint">{hint && formatDate(hint)}</p>
      )}
    </fieldset>
  );
}
