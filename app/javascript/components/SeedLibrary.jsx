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
export default function SeedLibrary({tabs: initialTabs, html: initialHtml, groups, chips, crop: initialCrop, crop_search: cropSearch, placeholder}) {
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
    <Choice key={label} params={params} search={search} active={active} className={className} onChoose={show}>{label}</Choice>
  );
  const chip = (params, label, active = isChosen(params, query)) => choice(params, label, active, 'seed-chip');

  return (
    <>
      <div dangerouslySetInnerHTML={{__html: tabs}} onClick={onContentClick} />
      <div className="seed-toolbar">
        {cropSearch && (
          <div className="seed-search">
            {crop ? (
              <span className="seed-crop">
                {crop.name}
                <Choice params={{crop: null}} search={search} className="seed-crop-clear" onChoose={show}>
                  <span aria-hidden="true">×</span>
                  <span className="visually-hidden">Clear crop</span>
                </Choice>
              </span>
            ) : (
              <CropPicker
                id="seed-crop"
                compact
                autoFocus={false}
                label="Search seeds by crop"
                placeholder={placeholder}
                onChoose={(chosen) => show(addressWith({crop: chosen.slug}, search))}
              />
            )}
          </div>
        )}
        <div className="seed-group-by">
          <span className="seed-toolbar-label">Group by</span>
          {groups.map(([key, label]) => chip({group: key}, label, (query.get('group') || 'crop') === key))}
        </div>
        <div className="seed-seg" role="group" aria-label="View as">
          {choice({view: null}, 'Cards', query.get('view') !== 'list')}
          {choice({view: 'list'}, 'List', query.get('view') === 'list')}
        </div>
      </div>
      <ul className="seed-chips">
        {chips.map(({label, params}) => <li key={label}>{chip(params, label)}</li>)}
      </ul>
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
