import React, {useEffect, useRef, useState} from 'react';

const normal = (text) => text.trim().toLowerCase();

// Parts that start with what was typed first (an exact match before any other),
// then parts that contain it. With nothing typed, all of them, with the
// suggested one (what this crop is usually harvested for) at the top.
function matching(parts, text, suggestedId) {
  const term = normal(text);
  if (!term) return [...parts].sort((a, b) => (b.id === suggestedId) - (a.id === suggestedId));
  const rank = (part) => {
    const name = normal(part.name);
    if (name === term) return 0;
    if (name.startsWith(term)) return 1;
    return name.includes(term) ? 2 : 3;
  };
  return parts.filter((part) => rank(part) < 3).sort((a, b) => rank(a) - rank(b));
}

// One big question, "What part did you harvest?", with a text box that
// completes the answer from the plant parts we have ("fruit", "leaf", ...), in
// the same style as the crop picker. Choosing one calls onChoose(part); the
// dialog then moves on to how much.
//
// A combobox with a listbox of matches: Up and Down move through them, Enter
// chooses the highlighted one (or the top match if none is highlighted), and
// Escape closes the list before it would close the dialog.
export default function PlantPartPicker({id, parts, suggestedId, onChoose}) {
  const [term, setTerm] = useState('');
  const [open, setOpen] = useState(true); // the list starts open, showing every part
  const [activeIndex, setActiveIndex] = useState(-1);
  const list = useRef(null);
  const listId = `${id}-results`;
  const results = matching(parts, term, suggestedId);
  const showing = open && results.length > 0;
  const noMatch = term.trim() !== '' && results.length === 0;

  useEffect(() => {
    const option = activeIndex >= 0 && list.current && list.current.children[activeIndex];
    if (option && option.scrollIntoView) option.scrollIntoView({block: 'nearest'});
  }, [activeIndex]);

  function onKeyDown(event) {
    if (event.key === 'ArrowDown') {
      event.preventDefault();
      if (showing) setActiveIndex((activeIndex + 1) % results.length);
      else setOpen(true);
    } else if (event.key === 'ArrowUp' && showing) {
      event.preventDefault();
      setActiveIndex(activeIndex <= 0 ? results.length - 1 : activeIndex - 1);
    } else if (event.key === 'Enter') {
      // Never submit a form from here: choose a part, or do nothing.
      event.preventDefault();
      if (showing) onChoose(results[activeIndex >= 0 ? activeIndex : 0]);
    } else if (event.key === 'Escape' && showing) {
      // Close the list; a second Escape then closes the dialog.
      event.stopPropagation();
      setOpen(false);
    }
  }

  const active = activeIndex >= 0 ? results[activeIndex] : null;

  return (
    <div className="crop-picker position-relative">
      <label htmlFor={id} className="crop-picker-label">What part did you harvest?</label>
      <div className="crop-picker-field">
        <i className="fas fa-search crop-picker-icon" aria-hidden="true" />
        <input
          id={id}
          type="text"
          role="combobox"
          className="crop-picker-input"
          autoFocus
          aria-autocomplete="list"
          aria-expanded={showing}
          aria-controls={listId}
          aria-activedescendant={active ? `${id}-option-${active.id}` : undefined}
          aria-describedby={`${id}-status`}
          autoComplete="off"
          placeholder="Start typing, e.g. fruit or leaf"
          value={term}
          onChange={(event) => {
            setTerm(event.target.value);
            setOpen(true);
            setActiveIndex(-1);
          }}
          onKeyDown={onKeyDown}
        />
      </div>
      <div id={`${id}-status`} className="crop-picker-hint" role="status">
        {showing
          ? `${results.length} ${results.length === 1 ? 'part' : 'parts'} found. Use the up and down arrow keys, then Enter, to choose one.`
          : 'Type to search, then choose a plant part.'}
      </div>
      {noMatch && (
        <div className="crop-picker-empty">
          <i className="fas fa-info-circle" aria-hidden="true" /> No plant parts match &ldquo;{term}&rdquo;.
        </div>
      )}
      {showing && (
        <ul id={listId} ref={list} role="listbox" aria-label="Matching plant parts" className="crop-picker-options shadow">
          {results.map((part, index) => (
            <li
              key={part.id}
              id={`${id}-option-${part.id}`}
              role="option"
              aria-selected={index === activeIndex}
              className={`crop-picker-option${index === activeIndex ? ' crop-picker-option-active' : ''}`}
              // mousedown, not click, so the input keeps focus while we choose.
              onMouseDown={(event) => {
                event.preventDefault();
                onChoose(part);
              }}
              onMouseEnter={() => setActiveIndex(index)}
            >
              {part.icon_url && (
                <img src={part.icon_url} alt="" aria-hidden="true" className="plant-part-icon" />
              )}
              {part.name}
              {!term.trim() && part.id === suggestedId && <span className="crop-picker-usual"> · usual for this crop</span>}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
