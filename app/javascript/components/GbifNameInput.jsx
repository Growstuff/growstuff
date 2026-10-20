import React, {useEffect, useRef, useState} from 'react';

import {getJson} from '../api';

const SEARCH_DELAY = 250; // ms to wait for typing to pause before searching
const MIN_LENGTH = 3; // GBIF's suggestions are too broad for fewer letters

// A text field that suggests scientific names from GBIF as you type. Choosing
// one fills in its canonical name; anything typed is still submitted as it is.
//
// A combobox with a listbox of matches: Up and Down move through them, Enter
// chooses the highlighted one (and otherwise leaves the form to submit), and
// Escape closes the list.
//
// The matches float over what is under the field, using the crop picker's
// styles.
export default function GbifNameInput({id, name, value, onChange, url}) {
  const [matches, setMatches] = useState([]);
  const [activeIndex, setActiveIndex] = useState(-1);
  const chosen = useRef(null); // the name last chosen, which needs no search
  const open = matches.length > 0;
  const active = activeIndex >= 0 ? matches[activeIndex] : null;

  useEffect(() => {
    const term = value.trim();
    if (term.length < MIN_LENGTH || term === chosen.current) {
      setMatches([]);
      return undefined;
    }

    const controller = new AbortController();
    const timer = setTimeout(async () => {
      try {
        const {ok, data} = await getJson(`${url}?term=${encodeURIComponent(term)}`, {signal: controller.signal});
        setMatches(ok && Array.isArray(data) ? data : []);
        setActiveIndex(-1);
      } catch (error) {
        if (error.name !== 'AbortError') setMatches([]);
      }
    }, SEARCH_DELAY);

    return () => {
      clearTimeout(timer);
      controller.abort();
    };
  }, [value, url]);

  function choose(match) {
    chosen.current = match.canonicalName;
    setMatches([]);
    onChange(match.canonicalName);
  }

  function onKeyDown(event) {
    if (event.key === 'ArrowDown' && open) {
      event.preventDefault();
      setActiveIndex((activeIndex + 1) % matches.length);
    } else if (event.key === 'ArrowUp' && open) {
      event.preventDefault();
      setActiveIndex(activeIndex <= 0 ? matches.length - 1 : activeIndex - 1);
    } else if (event.key === 'Enter' && active) {
      event.preventDefault(); // choosing a match, not submitting the form
      choose(active);
    } else if (event.key === 'Escape' && open) {
      event.stopPropagation();
      setMatches([]);
    }
  }

  return (
    <div className="crop-picker crop-picker-compact position-relative flex-grow-1">
      <input
        type="text"
        className="form-control"
        id={id}
        name={name}
        role="combobox"
        aria-autocomplete="list"
        aria-expanded={open}
        aria-controls={`${id}-matches`}
        aria-activedescendant={active ? `${id}-match-${activeIndex}` : undefined}
        autoComplete="off"
        value={value}
        onChange={(event) => onChange(event.target.value)}
        onKeyDown={onKeyDown}
        onBlur={() => setMatches([])}
      />
      {open && (
        <ul id={`${id}-matches`} role="listbox" aria-label="Matching scientific names" className="crop-picker-options shadow">
          {matches.map((match, index) => (
            <li
              key={match.key ?? index}
              id={`${id}-match-${index}`}
              role="option"
              aria-selected={index === activeIndex}
              className={`crop-picker-option${index === activeIndex ? ' crop-picker-option-active' : ''}`}
              // mousedown, not click, so the field keeps focus while we choose.
              onMouseDown={(event) => {
                event.preventDefault();
                choose(match);
              }}
              onMouseEnter={() => setActiveIndex(index)}
            >
              {match.canonicalName} ({match.scientificName}) &ndash; {match.rank}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
