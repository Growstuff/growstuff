import React, {useEffect, useState} from 'react';

import {getJson} from '../api';

// Search-as-you-type for a crop, using the same /crops/search.json as the
// existing form's autosuggest (which puts crops you have planted first).
// `value` is the chosen {id, name}, or null.
export default function CropPicker({id, value, onChange, invalid}) {
  const [term, setTerm] = useState('');
  const [results, setResults] = useState([]);
  const [noMatch, setNoMatch] = useState(false); // a search finished and found nothing

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

  function choose(crop) {
    onChange({id: crop.id, name: crop.name});
    setTerm('');
    setResults([]);
  }

  if (value) {
    return (
      <span>
        <span className="madlib-chosen">{value.name}</span>
        <button type="button" className="btn btn-sm btn-link" onClick={() => onChange(null)}>
          Change<span className="sr-only"> crop</span>
        </button>
      </span>
    );
  }

  return (
    <span className="position-relative d-inline-block">
      <input
        id={id}
        type="text"
        className={`madlib-field madlib-crop${invalid ? ' is-invalid' : ''}`}
        aria-label="Crop"
        autoComplete="off"
        placeholder="type a crop name"
        value={term}
        onChange={(event) => setTerm(event.target.value)}
        onKeyDown={(event) => {
          // Enter picks the top match, rather than submitting the form without a crop.
          if (event.key === 'Enter' && results.length > 0) {
            event.preventDefault();
            choose(results[0]);
          }
        }}
        aria-describedby={`${id}-status`}
      />
      <span id={`${id}-status`} className="sr-only" role="status">
        {term.trim() && results.length > 0 ? `${results.length} crops found` : ''}
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
      {results.length > 0 && (
        <ul className="list-group position-absolute shadow" style={{zIndex: 1060, maxHeight: '16rem', overflowY: 'auto', minWidth: '14rem', textAlign: 'left', fontSize: '1rem', lineHeight: 1.5}}>
          {results.map((crop) => (
            <li key={crop.id} className="list-group-item p-0">
              <button type="button" className="btn btn-link text-left w-100" onClick={() => choose(crop)}>
                {crop.name}
              </button>
            </li>
          ))}
        </ul>
      )}
    </span>
  );
}
