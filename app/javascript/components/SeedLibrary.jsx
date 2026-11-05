import React, {useEffect, useRef, useState} from 'react';

import {mountIslands, unmountIslands} from '../islands';
import CropPicker from './CropPicker';

// Whether a control's params are what the address says now: a param that is
// null must be absent.
const isChosen = (params, query) => (
  Object.entries(params).every(([key, value]) => (query.get(key) || '') === (value == null ? '' : String(value)))
);

// This page's address with some params set, or taken off when null, and back
// to the first page.
function addressWith(params, search) {
  const url = new URL(window.location.pathname + search, window.location.origin);
  Object.entries(params).forEach(([key, value]) => {
    if (value == null) url.searchParams.delete(key);
    else url.searchParams.set(key, value);
  });
  url.searchParams.delete('page');
  return url.pathname + url.search;
}

// Not for us to take over: another tab or window, a modified click, a file
// to download, another page, or the open data (csv, json, rss).
function staysOnPage(event, link) {
  if (event.defaultPrevented || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return false;
  if ((link.target && link.target !== '_self') || link.hasAttribute('download') || link.dataset.method) return false;

  const url = new URL(link.href, window.location.href);
  return url.origin === window.location.origin
    && url.pathname === window.location.pathname
    && !/\.(csv|json|rss)$/.test(url.pathname);
}

// One link that changes what is shown without leaving the page.
function Choice({params, search, active, className, onChoose, children}) {
  const href = addressWith(params, search);
  return (
    <a
      href={href}
      className={[className, active && 'active'].filter(Boolean).join(' ')}
      aria-current={active ? 'true' : undefined}
      onClick={(event) => {
        if (!staysOnPage(event, event.currentTarget)) return;
        event.preventDefault();
        onChoose(href);
      }}
    >
      {children}
    </a>
  );
}

// The seed library's controls, with the tabs above them and the results under
// them. Choosing anything changes the address and fetches the tabs and results
// again, which Rails renders (seeds/_tabs, seeds/_results) and this puts in
// place. Links in the tabs and results that stay on this page, such as the
// pages, do the same. Back and forward work.
export default function SeedLibrary({scope: initialScope, tabs: initialTabs, html: initialHtml, labels, groups, filters, sow_now: sowNow, gardeners, months = [], clear = {}, crop: initialCrop, crop_search: cropSearch, placeholder}) {
  const [scope, setScope] = useState(initialScope);
  const [tabs, setTabs] = useState(initialTabs);
  const [html, setHtml] = useState(initialHtml);
  const [search, setSearch] = useState(window.location.search);
  const [crop, setCrop] = useState(initialCrop);
  const [loading, setLoading] = useState(false);
  const results = useRef(null);
  const request = useRef(null);
  const query = new URLSearchParams(search);

  // Islands inside the results (the piles of packets) need mounting.
  useEffect(() => {
    mountIslands(results.current);
  }, [html]);

  async function show(address, {push = true} = {}) {
    if (request.current) request.current.abort();
    const controller = new AbortController();
    request.current = controller;
    setLoading(true);

    try {
      const response = await fetch(address, {
        credentials: 'same-origin',
        headers: {'Accept': 'application/json', 'X-Seed-Library': 'results'},
        signal: controller.signal,
      });
      if (!response.ok) throw new Error(`${response.status}`);

      const body = await response.json();
      unmountIslands(results.current);
      setScope(body.scope);
      setTabs(body.tabs);
      setHtml(body.results);
      setCrop(body.crop);
      setSearch(new URL(address, window.location.origin).search);
      if (push) window.history.pushState({}, '', address);
      setLoading(false);
    } catch (error) {
      if (error.name === 'AbortError') return;
      window.location.assign(address); // let the page do it the long way
    }
  }

  useEffect(() => {
    const back = () => show(window.location.pathname + window.location.search, {push: false});
    window.addEventListener('popstate', back);
    return () => window.removeEventListener('popstate', back);
  }, []);

  // Links in the tabs and the results that only change what this page shows.
  function onContentClick(event) {
    const link = event.target.closest('a[href]');
    if (!link || !event.currentTarget.contains(link) || !staysOnPage(event, link)) return;

    event.preventDefault();
    show(link.pathname + link.search);
    if (link.closest('.pagination')) results.current.scrollIntoView({block: 'start'});
  }

  // A link that changes what is shown, in whichever look the control has.
  const choice = (params, label, active, className) => (
    <Choice key={label} params={params} search={pendingSearch} active={active} className={className} onChoose={show}>{label}</Choice>
  );
  // A filter chip: choosing it adds that filter to the others in force, and
  // choosing it again takes it off.
  const chip = ({label, params}) => {
    const active = isChosen(params, query);
    const takesOff = active && Object.values(params).some((value) => value != null);
    const off = Object.fromEntries(Object.keys(params).map((key) => [key, null]));
    return <li key={label}>{choice(takesOff ? off : params, label, active, 'seed-chip')}</li>;
  };
  const [gardener, setGardener] = useState(query.get('gardener') || '');
  useEffect(() => setGardener(new URLSearchParams(search).get('gardener') || ''), [search]);
  const chooseGardener = (name) => {
    if ((query.get('gardener') || '') !== name.trim()) show(addressWith({gardener: name.trim() || null}, search));
  };
  // The address as it will be once a gardener typed but not yet entered is
  // counted, so choosing another control does not lose the name.
  const pendingSearch = (() => {
    if (!gardeners) return search;
    const pending = new URLSearchParams(search);
    if (gardener.trim()) pending.set('gardener', gardener.trim());
    else pending.delete('gardener');
    return pending.size ? `?${pending}` : '';
  })();
  const filtering = Object.keys(clear).some((key) => query.has(key));

  return (
    <>
      <div dangerouslySetInnerHTML={{__html: scope}} onClick={onContentClick} />
      <div dangerouslySetInnerHTML={{__html: tabs}} onClick={onContentClick} />
      <div className="seed-filters">
        <div className="seed-filter-row">
          {cropSearch && (
            <div className="seed-field">
              <span className="seed-field-label">{labels.crop}</span>
              <div className="seed-search">
                {crop ? (
                  <span className="seed-crop">
                    {crop.name}
                    <Choice params={{crop: null}} search={pendingSearch} className="seed-crop-clear" onChoose={show}>
                      <span aria-hidden="true">×</span>
                      <span className="visually-hidden">{labels.clear_crop}</span>
                    </Choice>
                  </span>
                ) : (
                  <CropPicker
                    id="seed-crop"
                    compact
                    autoFocus={false}
                    label={labels.search_crop}
                    placeholder={placeholder}
                    onChoose={(chosen) => show(addressWith({crop: chosen.slug}, pendingSearch))}
                  />
                )}
              </div>
            </div>
          )}
          {filtering && (
            <Choice params={clear} search={pendingSearch} className="seed-clear" onChoose={show}>{labels.clear_filters}</Choice>
          )}
        </div>
        <div className="seed-filter-row d-lg-none">
          <div className="seed-field">
            <label className="seed-field-label" htmlFor="seed-month">{labels.month_to_sow}</label>
            <select
              id="seed-month"
              className="seed-month form-select form-select-sm"
              value={query.get('sow_month') || ''}
              onChange={(event) => show(addressWith({sow_month: event.target.value || null}, pendingSearch))}
            >
              <option value="">{labels.any_month}</option>
              <option value="now">{sowNow}</option>
              {months.map(([number, name]) => <option key={number} value={number}>{name}</option>)}
            </select>
          </div>
        </div>
        {gardeners && (
          <div className="seed-filter-row">
            <div className="seed-field">
              <label className="seed-field-label" htmlFor="seed-gardener">{labels.gardener}</label>
              <input
                id="seed-gardener"
                className="seed-gardener form-control form-control-sm"
                type="search"
                list="seed-gardeners"
                placeholder={labels.gardener_placeholder}
                autoComplete="off"
                value={gardener}
                onChange={(event) => {
                  setGardener(event.target.value);
                  if (gardeners.includes(event.target.value)) chooseGardener(event.target.value);
                }}
                onKeyDown={(event) => { if (event.key === 'Enter') chooseGardener(gardener); }}
                onBlur={() => chooseGardener(gardener)}
              />
              <datalist id="seed-gardeners">
                {gardeners.map((name) => <option key={name} value={name} />)}
              </datalist>
            </div>
          </div>
        )}
        {filters.map(({label, chips, wide_only: wideOnly}) => (
          <div className={`seed-filter-row${wideOnly ? ' d-none d-lg-flex' : ''}`} key={label}>
            <div className="seed-field">
              <span className="seed-field-label">{label}</span>
              <ul className="seed-chips">{chips.map(chip)}</ul>
            </div>
          </div>
        ))}
      </div>
      <div className="seed-display">
        <div className="seed-display-group">
          <span className="seed-field-label">{labels.group_by}</span>
          <div className="seed-seg" role="group" aria-label={labels.group_by}>
            {groups.map(([key, label]) => choice({group: key}, label, (query.get('group') || 'crop') === key))}
          </div>
        </div>
        <div className="seed-display-group">
          <span className="seed-field-label">{labels.view}</span>
          <div className="seed-seg" role="group" aria-label={labels.view}>
            {choice({view: null}, labels.cards, query.get('view') !== 'list')}
            {choice({view: 'list'}, labels.list, query.get('view') === 'list')}
          </div>
        </div>
      </div>
      <div
        ref={results}
        className={`seed-results${loading ? ' is-loading' : ''}`}
        aria-busy={loading}
        dangerouslySetInnerHTML={{__html: html}}
        onClick={onContentClick}
      />
    </>
  );
}
