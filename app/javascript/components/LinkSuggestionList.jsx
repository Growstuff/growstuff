import React from 'react';

// The matches for what has been typed after an @ in the post editor, grouped
// (Crops, Members, Yours) and floating under the cursor. The editor owns which
// is highlighted and handles the keys; this only draws the list.
export default function LinkSuggestionList({items, selected, rect, onChoose}) {
  if (!rect || items.length === 0) return null;

  let lastGroup = null;
  return (
    <div
      className="link-suggestions shadow"
      style={{position: 'fixed', left: rect.left, top: rect.bottom + 4}}
    >
      <ul role="listbox" aria-label="Link to…" className="list-unstyled mb-0">
        {items.map((item, index) => {
          const heading = item.group !== lastGroup;
          lastGroup = item.group;
          return (
            <React.Fragment key={`${item.kind}-${item.slug || item.label}`}>
              {heading && <li role="presentation" className="link-suggestions-group">{item.group}</li>}
              <li
                role="option"
                aria-selected={index === selected}
                className={`link-suggestions-item${index === selected ? ' active' : ''}`}
                // mousedown, not click, so the editor keeps focus while we choose.
                onMouseDown={(event) => {
                  event.preventDefault();
                  onChoose(item);
                }}
              >
                <strong>{item.label}</strong>
                {item.detail && <small className="text-muted d-block">{item.detail}</small>}
              </li>
            </React.Fragment>
          );
        })}
      </ul>
      <div className="link-suggestions-hint text-muted">↑↓ to choose · Enter to link · Esc to keep it as text</div>
    </div>
  );
}
