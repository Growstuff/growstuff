import React, {useEffect, useRef, useState} from 'react';

import {getJson} from '../api';

const SEARCH_DELAY = 250; // ms to wait for typing to pause before searching

const IDLE = {status: 'idle', results: []};

// Searches /crops/search.json as you type (the same search as the existing
// form's autosuggest, which puts crops you have planted first). `status` is
// 'idle', 'searching' (still showing the last results), 'done', or 'none' for a
// finished search that found nothing. Call `reset` to close the matches.
function useCropSearch(term) {
  const [search, setSearch] = useState(IDLE);

  useEffect(() => {
    if (!term.trim()) {
      setSearch(IDLE);
      return undefined;
    }
    setSearch((current) => ({...current, status: 'searching'}));

    const controller = new AbortController();
    const timer = setTimeout(async () => {
      try {
        const {ok, data} = await getJson(`/crops/search.json?term=${encodeURIComponent(term)}`, {signal: controller.signal});
        const results = ok && Array.isArray(data) ? data : [];
        setSearch({status: ok && results.length === 0 ? 'none' : 'done', results});
      } catch (error) {
        if (error.name !== 'AbortError') setSearch(IDLE);
      }
    }, SEARCH_DELAY);

    return () => {
      clearTimeout(timer);
      controller.abort();
    };
  }, [term]);

  return [search, () => setSearch(IDLE)];
}

function hint({status, results}) {
  if (status === 'searching') return 'Searching…';
  if (results.length > 0) {
    return `${results.length} ${results.length === 1 ? 'crop' : 'crops'} found. Use the up and down arrow keys, then Enter, to choose one.`;
  }
  return 'Search for a crop, then choose it.';
}

function Options({id, results, activeIndex, listRef, onChoose, onHover}) {
  return (
    <ul id={`${id}-results`} ref={listRef} role="listbox" aria-label="Matching crops" className="crop-picker-options shadow">
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
            onChoose(crop);
          }}
          onMouseEnter={() => onHover(index)}
        >
          {crop.name}
        </li>
      ))}
    </ul>
  );
}

// Choose a crop by searching for it. Choosing one calls onChoose({id, name, slug}).
//
// A combobox with a listbox of matches: Up and Down move through them, Enter
// chooses the highlighted one (or the top match if none is highlighted), and
// Escape closes the list before it would close a dialog it is in.
//
// `label` and `placeholder` say what is being asked. `compact` is the small
// version for a toolbar: an ordinary box, its label and hint kept for screen
// readers only, and the matches floating over the page.
export default function CropPicker({
  id,
  onChoose,
  label = 'What did you plant?',
  placeholder = 'Start typing a crop name',
  autoFocus = true,
  compact = false,
}) {
  const [term, setTerm] = useState('');
  const [search, resetSearch] = useCropSearch(term);
  const [activeIndex, setActiveIndex] = useState(-1);
  const list = useRef(null);
  const {results, status} = search;
  const open = results.length > 0;
  const activeCrop = activeIndex >= 0 ? results[activeIndex] : null;

  // A new set of matches starts with none highlighted.
  useEffect(() => setActiveIndex(-1), [results]);

  // Keep the highlighted match in view when the list scrolls.
  useEffect(() => {
    const option = activeIndex >= 0 && list.current && list.current.children[activeIndex];
    if (option && option.scrollIntoView) option.scrollIntoView({block: 'nearest'});
  }, [activeIndex]);

  function choose(crop) {
    setTerm('');
    resetSearch();
    onChoose({id: crop.id, name: crop.name, slug: crop.slug});
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
    } else if (event.key === 'Escape' && (open || status === 'none')) {
      // Close the list; a second Escape then closes the dialog.
      event.stopPropagation();
      resetSearch();
    }
  }

  return (
    <div className={`crop-picker position-relative${compact ? ' crop-picker-compact' : ''}`}>
      <label htmlFor={id} className={compact ? 'visually-hidden' : 'crop-picker-label'}>{label}</label>
      <div className="crop-picker-field">
        <i className="fas fa-search crop-picker-icon" aria-hidden="true" />
        <input
          id={id}
          type="text"
          role="combobox"
          className="crop-picker-input"
          autoFocus={autoFocus}
          aria-autocomplete="list"
          aria-expanded={open}
          aria-controls={`${id}-results`}
          aria-activedescendant={activeCrop ? `${id}-option-${activeCrop.id}` : undefined}
          aria-describedby={`${id}-status`}
          autoComplete="off"
          placeholder={placeholder}
          value={term}
          onChange={(event) => setTerm(event.target.value)}
          onKeyDown={onKeyDown}
        />
        {status === 'searching' && <i className="fas fa-spinner fa-spin crop-picker-spinner" aria-hidden="true" />}
      </div>
      <div id={`${id}-status`} className={compact ? 'visually-hidden' : 'crop-picker-hint'} role="status">
        {hint(search)}
      </div>
      {status === 'none' && (
        <div className="crop-picker-empty">
          <i className="fas fa-info-circle" aria-hidden="true" />{' '}
          No crops match &ldquo;{term}&rdquo;.{' '}
          <a href="/crops/new" target="_blank" rel="noopener noreferrer">Request a new crop</a>
        </div>
      )}
      {open && <Options id={id} results={results} activeIndex={activeIndex} listRef={list} onChoose={choose} onHover={setActiveIndex} />}
    </div>
  );
}
