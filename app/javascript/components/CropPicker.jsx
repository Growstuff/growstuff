import React, {useEffect, useRef, useState} from 'react';

import {getJson} from '../api';

function hint(searching, open, count) {
  if (searching) return 'Searching…';
  if (open) return `${count} ${count === 1 ? 'crop' : 'crops'} found. Use the up and down arrow keys, then Enter, to choose one.`;
  return 'Search for a crop, then choose it.';
}

// One big question, "What did you plant?", with search-as-you-type for the
// answer, using the same /crops/search.json as the existing form's autosuggest
// (which puts crops you have planted first). Choosing a crop calls onChoose(crop);
// the dialog then shows it for confirmation.
//
// A combobox with a listbox of matches: Up and Down move through them, Enter
// chooses the highlighted one (or the top match if none is highlighted), and
// Escape closes the list before it would close the dialog.
export default function CropPicker({id, onChoose}) {
  const [term, setTerm] = useState('');
  const [results, setResults] = useState([]);
  const [noMatch, setNoMatch] = useState(false); // a search finished and found nothing
  const [searching, setSearching] = useState(false);
  const [activeIndex, setActiveIndex] = useState(-1);
  const list = useRef(null);
  const listId = `${id}-results`;
  const open = results.length > 0;

  useEffect(() => {
    setNoMatch(false);
    if (!term.trim()) {
      setResults([]);
      setSearching(false);
      return undefined;
    }
    setSearching(true);

    const controller = new AbortController();
    const timer = setTimeout(async () => {
      try {
        const {ok, data} = await getJson(`/crops/search.json?term=${encodeURIComponent(term)}`, {signal: controller.signal});
        const found = ok && Array.isArray(data) ? data : [];
        setResults(found);
        setActiveIndex(-1);
        setNoMatch(ok && found.length === 0);
        setSearching(false);
      } catch (error) {
        if (error.name !== 'AbortError') {
          setResults([]);
          setSearching(false);
        }
      }
    }, 250);

    return () => {
      clearTimeout(timer);
      controller.abort();
    };
  }, [term]);

  // Keep the highlighted match in view when the list scrolls.
  useEffect(() => {
    const option = activeIndex >= 0 && list.current && list.current.children[activeIndex];
    if (option && option.scrollIntoView) option.scrollIntoView({block: 'nearest'});
  }, [activeIndex]);

  function choose(crop) {
    setTerm('');
    setResults([]);
    onChoose({id: crop.id, name: crop.name});
  }

  function onKeyDown(event) {
    if (event.key === 'ArrowDown' && open) {
      event.preventDefault();
      setActiveIndex((activeIndex + 1) % results.length);
    } else if (event.key === 'ArrowUp' && open) {
      event.preventDefault();
      setActiveIndex(activeIndex <= 0 ? results.length - 1 : activeIndex - 1);
    } else if (event.key === 'Enter') {
      // Never submit a form from here: choose a crop, or do nothing.
      event.preventDefault();
      if (open) choose(results[activeIndex >= 0 ? activeIndex : 0]);
    } else if (event.key === 'Escape' && (open || noMatch)) {
      // Close the list; a second Escape then closes the dialog.
      event.stopPropagation();
      setResults([]);
      setNoMatch(false);
    }
  }

  const activeCrop = activeIndex >= 0 ? results[activeIndex] : null;

  return (
    <div className="crop-picker position-relative">
      <label htmlFor={id} className="crop-picker-label">What did you plant?</label>
      <div className="crop-picker-field">
        <i className="fa fa-search crop-picker-icon" aria-hidden="true" />
        <input
          id={id}
          type="text"
          role="combobox"
          className="crop-picker-input"
          autoFocus
          aria-autocomplete="list"
          aria-expanded={open}
          aria-controls={listId}
          aria-activedescendant={activeCrop ? `${id}-option-${activeCrop.id}` : undefined}
          aria-describedby={`${id}-status`}
          autoComplete="off"
          placeholder="Start typing a crop name"
          value={term}
          onChange={(event) => setTerm(event.target.value)}
          onKeyDown={onKeyDown}
        />
        {searching && <i className="fa fa-spinner fa-spin crop-picker-spinner" aria-hidden="true" />}
      </div>
      <div id={`${id}-status`} className="crop-picker-hint" role="status">
        {hint(searching, open, results.length)}
      </div>
      {noMatch && (
        <div className="crop-picker-empty">
          <i className="fa fa-info-circle" aria-hidden="true" />{' '}
          No crops match &ldquo;{term}&rdquo;.{' '}
          <a href="/crops/new" target="_blank" rel="noopener noreferrer">Request a new crop</a>
        </div>
      )}
      {open && (
        <ul id={listId} ref={list} role="listbox" aria-label="Matching crops" className="crop-picker-options shadow">
          {results.map((crop, index) => (
            <li
              key={crop.id}
              id={`${id}-option-${crop.id}`}
              role="option"
              aria-selected={index === activeIndex}
              className={`crop-picker-option${index === activeIndex ? ' crop-picker-option-active' : ''}`}
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
    </div>
  );
}
