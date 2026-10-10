import React, {useEffect, useRef, useState} from 'react';

import {patchJson} from '../api';
import {formatDate} from '../dates';

function errorMessage(status, data) {
  if (status === 422 && data && data.errors) {
    const [field, messages] = Object.entries(data.errors)[0] || [];
    if (field) return `${field.replace(/_/g, ' ').replace(/^./, (c) => c.toUpperCase())} ${messages[0]}`;
  }
  return 'Couldn\'t save the date. Please try again.';
}

// "Planted 12 Sep". When the viewer owns the planting it is a button with a
// pencil that opens the browser's own date picker, saved with the tick (or
// Enter) and dropped with the cross (or Escape). `onUpdated` gets the garden's
// refreshed card, so the row's predictions follow the new date.
export default function PlantedDate({planting, onUpdated}) {
  const {url, planted_at: plantedAt, can_edit: canEdit} = planting;
  const [editing, setEditing] = useState(false);
  const [value, setValue] = useState(plantedAt || '');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);
  const input = useRef(null);

  useEffect(() => {
    if (editing && input.current) input.current.focus();
  }, [editing]);

  if (!canEdit) return plantedAt ? <span className="planting-row-planted">Planted {formatDate(plantedAt)}</span> : null;

  function open() {
    setValue(plantedAt || '');
    setError(null);
    setEditing(true);
  }

  function cancel() {
    setEditing(false);
    setError(null);
  }

  async function save() {
    if (!value || value === plantedAt) return cancel();

    setSaving(true);
    setError(null);
    try {
      const {ok, status, data} = await patchJson(url, {planting: {planted_at: value}});
      if (ok) {
        setSaving(false);
        setEditing(false);
        onUpdated(data.garden);
        return;
      }
      setError(errorMessage(status, data));
    } catch (failure) {
      setError('Couldn\'t reach the server. Please try again.');
    }
    setSaving(false);
  }

  function onKeyDown(event) {
    if (event.key === 'Enter') {
      event.preventDefault();
      save();
    } else if (event.key === 'Escape') {
      cancel();
    }
  }

  if (!editing) {
    return (
      <button type="button" className="planting-row-planted planting-date-button" onClick={open} title="Change the planted date">
        {plantedAt ? `Planted ${formatDate(plantedAt)}` : 'Set planted date'}
        <i className="fas fa-pencil" aria-hidden="true" />
      </button>
    );
  }

  return (
    <span className="planting-date-editor">
      <input
        ref={input}
        type="date"
        className="form-control form-control-sm"
        aria-label="Planted date"
        value={value}
        disabled={saving}
        onChange={(event) => setValue(event.target.value)}
        onKeyDown={onKeyDown}
      />
      <button type="button" className="btn btn-sm btn-link" onClick={save} disabled={saving || !value} aria-label="Save planted date">
        <i className="fas fa-check" aria-hidden="true" />
      </button>
      <button type="button" className="btn btn-sm btn-link" onClick={cancel} disabled={saving} aria-label="Cancel">
        <i className="fas fa-times" aria-hidden="true" />
      </button>
      {error && <small className="planting-date-error" role="alert">{error}</small>}
    </span>
  );
}
