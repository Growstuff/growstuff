import React from 'react';

// A Bootstrap dropdown of links. The server decides the items (label, href,
// and for non-GET links `method` and `confirm`); we render them with the
// data-method / data-confirm attributes that jquery_ujs already handles, and
// Bootstrap's delegated data-api drives the dropdown, so neither needs to
// know about React.
export default function ActionsMenu({id, actions, label = 'Actions', ariaLabel, className = 'btn dropdown-toggle', onSelect}) {
  if (!actions || actions.length === 0) return null;

  const buttonId = `actions-${id}`;

  return (
    <div className="dropdown garden-actions">
      <a
        id={buttonId}
        className={className}
        href="#"
        role="button"
        data-bs-toggle="dropdown"
        aria-expanded="false"
        aria-haspopup="true"
        aria-label={ariaLabel}
      >
        {label}
      </a>
      <div className="dropdown-menu dropdown-menu-end" aria-labelledby={buttonId}>
        {actions.map((action) => (
          <React.Fragment key={action.key}>
            {action.divider && <div className="dropdown-divider" />}
            <a
              className={`dropdown-item${action.key === 'delete' ? ' text-danger' : ''}`}
              href={action.href}
              data-method={action.method}
              data-confirm={action.confirm}
              onClick={(event) => onSelect && onSelect(action, event)}
            >
              {action.label}
            </a>
          </React.Fragment>
        ))}
      </div>
    </div>
  );
}
