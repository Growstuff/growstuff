import React, {useEffect, useRef, useState} from 'react';

import {getJson} from '../api';

// Search-as-you-type for a crop, using the same /crops/search.json as the
// existing form's autosuggest (which puts crops you have planted first).
// `value` is the chosen {id, name}, or null.
//
// A combobox with a listbox of matches: Up and Down move through them, Enter
// chooses the highlighted one (or the top match if none is highlighted), and
// Escape closes the list before it would close the dialog.
export default function CropPicker({id, value, onChange, invalid}) {
  const [term, setTerm] = useState('');
  const [results, setResults] = useState([]);
  const [noMatch, setNoMatch] = useState(false); // a search finished and found nothing
  const [activeIndex, setActiveIndex] = useState(-1);
  const changeButton = useRef(null);
  const list = useRef(null);
  const listId = `${id}-results`;
  const open = results.length > 0;

  useEffect(() => {
    setNoMatch(false);
    if (!term.trim() || value) {
      setResults([]);
      return undefined;
    }

    const controller = new AbortController();
    const timer = setTimeout(async () => {
      try {
        const {ok, data} = await getJson(`/crops/search.json?term=${encodeURIComponent(term)}`, {signal: controller.signal});
        const found = ok && Array.isArray(data) ? data : [];
        setResults(found);
        setActiveIndex(-1);
        setNoMatch(ok && found.length === 0);
      } catch (error) {
        if (error.name !== 'AbortError') setResults([]);
      }
    }, 250);

    return () => {
      clearTimeout(timer);
      controller.abort();
    };
  }, [term, value]);

  // Once a crop is chosen the input goes away, so put focus on "Change" rather than losing it.
  useEffect(() => {
    if (value && changeButton.current) changeButton.current.focus();
  }, [value]);

  // Keep the highlighted match in view when the list scrolls.
  useEffect(() => {
    const option = activeIndex >= 0 && list.current && list.current.children[activeIndex];
    if (option && option.scrollIntoView) option.scrollIntoView({block: 'nearest'});
  }, [activeIndex]);

  function choose(crop) {
    onChange({id: crop.id, name: crop.name});
    setTerm('');
    setResults([]);
  }

  function onKeyDown(event) {
    if (event.key === 'ArrowDown' && open) {
      event.preventDefault();
      setActiveIndex((activeIndex + 1) % results.length);
    } else if (event.key === 'ArrowUp' && open) {
      event.preventDefault();
      setActiveIndex(activeIndex <= 0 ? results.length - 1 : activeIndex - 1);
    } else if (event.key === 'Enter' && open) {
      // Choose a crop, rather than submitting the form without one.
      event.preventDefault();
      choose(results[activeIndex >= 0 ? activeIndex : 0]);
    } else if (event.key === 'Escape' && (open || noMatch)) {
      // Close the list; a second Escape then closes the dialog.
      event.stopPropagation();
      setResults([]);
      setNoMatch(false);
    }
  }

  if (value) {
    return (
      <span>
        <span className="madlib-chosen">{value.name}</span>
        <button ref={changeButton} type="button" className="btn btn-sm btn-link" onClick={() => onChange(null)}>
          Change<span className="sr-only"> crop</span>
        </button>
      </span>
    );
  }

  const activeCrop = activeIndex >= 0 ? results[activeIndex] : null;

  return (
    <span className="position-relative d-inline-block">
      <input
        id={id}
        type="text"
        role="combobox"
        className={`madlib-field madlib-crop${invalid ? ' is-invalid' : ''}`}
        aria-label="Crop"
        aria-autocomplete="list"
        aria-expanded={open}
        aria-controls={listId}
        aria-activedescendant={activeCrop ? `${id}-option-${activeCrop.id}` : undefined}
        aria-describedby={`${id}-status`}
        autoComplete="off"
        placeholder="type a crop name"
        value={term}
        onChange={(event) => setTerm(event.target.value)}
        onKeyDown={onKeyDown}
      />
      <span id={`${id}-status`} className="sr-only" role="status">
        {term.trim() && open ? `${results.length} crops found. Use the up and down arrow keys to choose.` : ''}
      </span>
      {noMatch && (
        <div
          className="position-absolute bg-white border rounded shadow p-2 text-left"
          style={{zIndex: 1060, minWidth: '16rem', fontSize: '1rem', lineHeight: 1.5}}
        >
          No crops match &ldquo;{term}&rdquo;.{' '}
          <a href="/crops/new" target="_blank" rel="noopener noreferrer">Request a new crop</a>
        </div>
      )}
      {open && (
        <ul
          id={listId}
          ref={list}
          role="listbox"
          aria-label="Matching crops"
          className="madlib-options position-absolute shadow"
        >
          {results.map((crop, index) => (
            <li
              key={crop.id}
              id={`${id}-option-${crop.id}`}
              role="option"
              aria-selected={index === activeIndex}
              className={`madlib-option${index === activeIndex ? ' madlib-option-active' : ''}`}
              // mousedown, not click, so the input keeps focus while we choose.
              onMouseDown={(event) => {
                event.preventDefault();
                choose(crop);
              }}
              onMouseEnter={() => setActiveIndex(index)}
            >
              {crop.name}
            </li>
          ))}
        </ul>
      )}
    </span>
  );
}
