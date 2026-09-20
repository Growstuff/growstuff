import React from 'react';

// Where you are in a dialog of steps: done steps get a tick, the current one is
// marked for assistive technology as well as by colour. `current` is 1-based.
export default function Steps({steps, current}) {
  return (
    <ol className="plant-steps" aria-label="Progress">
      {steps.map((label, index) => {
        const number = index + 1;
        const state = number < current ? 'done' : number === current ? 'current' : 'todo';
        return (
          <li key={label} className={`plant-step plant-step-${state}`} aria-current={state === 'current' ? 'step' : undefined}>
            <span className="plant-step-number">
              {state === 'done' ? <i className="fa fa-check" aria-hidden="true" /> : number}
            </span>
            {label}
            {state === 'done' && <span className="visually-hidden"> (done)</span>}
          </li>
        );
      })}
    </ol>
  );
}
