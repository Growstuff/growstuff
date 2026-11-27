import React, {useEffect, useRef, useState} from 'react';

import {initDomesticatedAnimals} from '../site/domesticated_animals';
import Modal from './Modal';

function AnimalForm({html, onClose, onSaved, errorLabel}) {
  const root = useRef(null);
  const [formHtml, setFormHtml] = useState(html);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(false);

  useEffect(() => {
    initDomesticatedAnimals(root.current);
    root.current.querySelector('input:not([type="hidden"])')?.focus();
  }, [formHtml]);

  useEffect(() => {
    root.current.querySelectorAll('[type="submit"]').forEach((button) => { button.disabled = saving; });
  }, [saving, formHtml]);

  async function submit(event) {
    event.preventDefault();
    if (saving) return;
    const form = event.target;
    const body = new FormData(form);
    setSaving(true);
    setError(false);
    try {
      const response = await fetch(form.action, {
        method: 'POST', body, credentials: 'same-origin', headers: {Accept: 'text/html'},
      });
      if (response.redirected) {
        onSaved(response.url);
        return;
      }
      if (response.status === 422) setFormHtml(await response.text());
      else setError(true);
    } catch {
      setError(true);
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="modal-body" aria-busy={saving}>
      {error && <p className="alert alert-danger" role="alert">{errorLabel}</p>}
      <div
        ref={root}
        onSubmit={submit}
        onClick={(event) => {
          if (event.target.closest('[data-animal-dialog-cancel="true"]')) {
            event.preventDefault();
            onClose();
          }
        }}
        dangerouslySetInnerHTML={{__html: formHtml}}
      />
    </div>
  );
}

export default function AnimalDialog({url, label, title, loading_label: loadingLabel, error_label: errorLabel}) {
  const [opened, setOpened] = useState(false);
  const [html, setHtml] = useState(null);

  useEffect(() => {
    if (!opened) return undefined;
    const controller = new AbortController();
    async function load() {
      try {
        const response = await fetch(`${url}?dialog=true`, {
          credentials: 'same-origin', headers: {Accept: 'text/html'}, signal: controller.signal,
        });
        if (!response.ok || response.redirected) throw new Error('Could not load form');
        setHtml(await response.text());
      } catch {
        if (!controller.signal.aborted) window.location.assign(url);
      }
    }
    load();
    return () => controller.abort();
  }, [opened, url]);

  const close = () => {
    setOpened(false);
    setHtml(null);
  };

  return (
    <>
      <a href={url} className="btn btn-sm section-add" onClick={(event) => {
        if (event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
        event.preventDefault();
        setOpened(true);
      }}>{label}</a>
      {opened && (
        <Modal title={title} titleId="animal-dialog-title" onClose={close}>
          {html
            ? <AnimalForm html={html} onClose={close} errorLabel={errorLabel} onSaved={(path) => window.location.assign(path)} />
            : <div className="modal-body" role="status">{loadingLabel}</div>}
        </Modal>
      )}
    </>
  );
}
