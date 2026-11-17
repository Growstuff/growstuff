import React, {useCallback, useEffect, useRef, useState} from 'react';

import {csrfToken, getJson, postJson} from '../api';
import {errorMessages} from '../errors';
import Modal from './Modal';
import Steps from './Steps';

// Flickr's own sign-in can't be shown inside the dialog, so it opens in a small
// window, and lands on a page that closes itself (see AuthenticationsController#connected).
// OmniAuth only starts a sign-in from a POST with a CSRF token, so it is a form submitted into the window.
const CONNECT_URL = '/members/auth/flickr';
const CONNECT_ORIGIN = '/authentications/connected';
const CONNECT_WINDOW = 'flickr-connect';

function ConnectFields() {
  return (
    <>
      <input type="hidden" name="authenticity_token" value={csrfToken()} />
      <input type="hidden" name="origin" value={CONNECT_ORIGIN} />
    </>
  );
}
const POLL_MS = 2000;

// Adding a photo to a planting, garden, job or the like, as a dialog over the page. The
// photos are the member's own, from their connected Flickr or Mastodon accounts.
// The server chooses the default source; a selector is offered when both are connected.
// Without an account, the first step offers connection options. Choose a photo (by album or tag, a page at a
// time), confirm it, and it is added and the page refreshed, so the page is never
// left. `newUrl` is the menu item's own link, /photos/new?type=..&id=..[&label=..].
export default function AddPhotoModal({label, newUrl, iconUrl, onClose, onAdded}) {
  const target = new URL(newUrl, window.location.origin).searchParams;
  const type = target.get('type');
  const id = target.get('id');
  const photoLabel = target.get('label'); // what part it is of: a job's before or after, a seed packet's front or back
  const createUrl = `/photos.json?${new URLSearchParams(photoLabel ? {type, id, label: photoLabel} : {type, id})}`;

  const [data, setData] = useState(null); // {state: connect | reconnect | ready, photos, sets, page, total_pages, ...}
  const [filters, setFilters] = useState({set: '', tag: '', page: 1});
  const [tagInput, setTagInput] = useState('');
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState(false);
  const [connectFirst, setConnectFirst] = useState(false); // opened without Flickr connected
  const [waiting, setWaiting] = useState(false); // the connect window is open
  const [blocked, setBlocked] = useState(false); // ...but the browser would not open it
  const [chosen, setChosen] = useState(null);
  const [saving, setSaving] = useState(false);
  const [errors, setErrors] = useState([]);
  const [source, setSource] = useState(target.get('source') || '');
  const [account, setAccount] = useState(target.get('authentication_id') || '');
  const [licenseAccepted, setLicenseAccepted] = useState(false);
  const popup = useRef(null);
  const connectForm = useRef(null);

  const load = useCallback(async (next, signal) => {
    const query = new URLSearchParams({type, id});
    if (source) query.set('source', source);
    if (account) query.set('authentication_id', account);
    if (next.cursor) query.set('cursor', next.cursor);
    if (next.set) query.set('set', next.set);
    if (next.tag) query.set('tag', next.tag);
    if (next.page > 1) query.set('page', next.page);
    const {ok, data: result} = await getJson(`/photos/new.json?${query}`, {signal});
    if (!ok) throw new Error('load failed');
    return result;
  }, [type, id, source, account]);

  useEffect(() => {
    const controller = new AbortController();
    setLoading(true);
    (async () => {
      try {
        const result = await load(filters, controller.signal);
        setData(result);
        setLoadError(false);
        if (result.state !== 'ready') setConnectFirst(true);
      } catch (error) {
        if (error.name !== 'AbortError') setLoadError(true);
      }
      if (!controller.signal.aborted) setLoading(false);
    })();
    return () => controller.abort();
  }, [filters, load]);

  // While the connect window is open, ask the server whether it worked.
  useEffect(() => {
    if (!waiting) return undefined;
    const timer = setInterval(async () => {
      try {
        const result = await load(filters);
        if (result.state === 'ready') {
          setData(result);
          setWaiting(false);
          if (popup.current && !popup.current.closed) popup.current.close();
        }
      } catch (error) {
        // Try again at the next tick.
      }
    }, POLL_MS);
    return () => clearInterval(timer);
  }, [waiting, filters, load]);

  function connect() {
    popup.current = window.open('', CONNECT_WINDOW, 'width=640,height=760');
    setBlocked(!popup.current);
    if (popup.current) connectForm.current.submit();
    setWaiting(true);
  }

  function search(event) {
    event.preventDefault();
    setFilters({set: '', tag: tagInput.trim(), page: 1});
  }

  function changeSource(value) {
    setSource(value);
    setChosen(null);
    setLicenseAccepted(false);
    setWaiting(false);
    setFilters({set: '', tag: '', page: 1});
    setTagInput('');
  }

  function changeAccount(value) {
    setAccount(value);
    setChosen(null);
    setLicenseAccepted(false);
    setFilters({set: '', tag: '', page: 1});
    setTagInput('');
  }

  function chooseAlbum(event) {
    setTagInput('');
    setFilters({set: event.target.value, tag: '', page: 1});
  }

  async function add() {
    setSaving(true);
    setErrors([]);
    try {
      const {ok, status, data: result} = await postJson(createUrl, {
        authentication_id: data.authentication_id,
        photo: {source_id: chosen.id, source: activeSource, ...(activeSource === 'mastodon' ? {status_id: chosen.status_id, license_accepted: licenseAccepted} : {})},
      });
      if (ok) {
        onAdded(result); // closes this dialog
        return;
      }
      setErrors(errorMessages(status, result, {signedOut: 'Please sign in again to add this photo.', fallback: 'Something went wrong adding that photo. Please try again.'}));
    } catch (error) {
      setErrors(['Couldn\'t reach the server. Please try again.']);
    }
    setSaving(false);
  }

  const ready = data && data.state === 'ready';
  const activeSource = data?.source || source || 'flickr';
  const mastodon = activeSource === 'mastodon';
  const sources = data?.sources || [];
  const labels = data?.labels || {};
  const needsLicense = mastodon && chosen && !chosen.license_name;
  const steps = connectFirst ? ['Connect Flickr', 'Choose a photo', 'Confirm'] : ['Choose a photo', 'Confirm'];
  const firstChoose = connectFirst ? 2 : 1;
  const current = !ready ? 1 : chosen ? firstChoose + 1 : firstChoose;

  const title = (
    <>
      {iconUrl && <img src={iconUrl} alt="" className="modal-title-icon" />}
      Add photo to {label}
    </>
  );

  return (
    <Modal title={title} titleId="add-photo-title" onClose={onClose}>
      {loadError && (
        <div className="modal-body plant-dialog-body">
          <div className="alert alert-danger mb-0" role="alert">Couldn&rsquo;t load your photos. Please close this and try again.</div>
        </div>
      )}
      {!loadError && !data && (
        <div className="modal-body plant-dialog-loading" role="status">
          <span>
            <i className="fas fa-spinner fa-spin" aria-hidden="true" /> Loading…
          </span>
        </div>
      )}
      {data && (
        <>
          <div className="modal-body plant-dialog-body">
            {data.labels && (
              <div className="photo-picker-filters mb-3">
                {sources.length > 1 && <>
                  <label htmlFor="photo-source">{labels.source}</label>
                  <select id="photo-source" className="form-select" value={activeSource} disabled={loading || saving} onChange={(event) => changeSource(event.target.value)}>
                    {sources.map((provider) => <option key={provider} value={provider}>{labels[provider]}</option>)}
                  </select>
                </>}
                {mastodon && data.accounts?.length > 0 && (
                  <>
                    <label htmlFor="photo-account">{labels.account}</label>
                    <select id="photo-account" className="form-select" value={account || data.authentication_id || data.accounts[0].id} disabled={loading || saving} onChange={(event) => changeAccount(event.target.value)}>
                      {data.accounts.map((auth) => <option key={auth.id} value={auth.id}>{auth.name}</option>)}
                    </select>
                  </>
                )}
              </div>
            )}
            {!mastodon && <Steps steps={steps} current={current} />}
            {mastodon && data.state === 'connect' && (
              <p>{labels.connect_hint} <a href={data.connect_mastodon_url}>{labels.connect}</a></p>
            )}
            {mastodon && data.state === 'unavailable' && <p role="alert">{data.error}</p>}

            {!ready && !mastodon && (
              <div className="crop-picker">
                <h3 className="crop-picker-label">{data.state === 'reconnect' ? 'Reconnect Flickr' : 'Connect your Flickr account'}</h3>
                <p>
                  Photos on Growstuff are shared from Flickr, so you choose them from your own photos there.{' '}
                  {data.state === 'reconnect' ? 'Your connection has expired, or been taken back on Flickr.' : 'Connect your account and you can choose one here.'}{' '}
                  Growstuff only reads your photos.
                </p>
                <form ref={connectForm} method="post" action={CONNECT_URL} target={CONNECT_WINDOW} hidden>
                  <ConnectFields />
                </form>
                <button type="button" className="btn btn-success btn-plant" onClick={connect} disabled={waiting} autoFocus>
                  <i className="fab fa-flickr" aria-hidden="true" /> {data.state === 'reconnect' ? 'Reconnect Flickr' : 'Connect Flickr'}
                </button>
                {waiting && (
                  <div className="photo-picker-waiting" role="status">
                    <i className="fas fa-spinner fa-spin" aria-hidden="true" />{' '}
                    {blocked ? 'Your browser blocked the window.' : 'Waiting for you to allow access on Flickr…'}{' '}
                    {blocked && (
                      <form method="post" action={CONNECT_URL} target="_blank" className="d-inline">
                        <ConnectFields />
                        <button type="submit" className="btn btn-link p-0 align-baseline">Connect in a new tab</button>
                      </form>
                    )}
                    {!blocked && <span className="photo-picker-hint">This picks up on its own once you have.</span>}
                  </div>
                )}
              </div>
            )}

            {ready && !chosen && (
              <div className="photo-picker">
                {/* The same big step heading the harvest and seeds dialogs use. */}
                <h3 className="crop-picker-label">Choose a photo</h3>
                <p className="photo-picker-hint">
                  {mastodon ? <>{data.name}. {labels.public_only}</> : <>From your Flickr, connected as <a href={data.profile_url} target="_blank" rel="noopener noreferrer">{data.name}</a>.</>}
                </p>
                <form className="photo-picker-filters" onSubmit={search}>
                  {data.sets.length > 0 && (
                    <>
                      <label className="visually-hidden" htmlFor="add-photo-album">Album</label>
                      <select id="add-photo-album" className="form-select" value={filters.set} onChange={chooseAlbum}>
                        <option value="">All your recent photos</option>
                        {data.sets.map((set) => <option key={set.id} value={set.id}>{set.title}</option>)}
                      </select>
                    </>
                  )}
                  <label className="visually-hidden" htmlFor="add-photo-tag">{mastodon ? labels.tag : 'Search by tag'}</label>
                  <input id="add-photo-tag" type="search" className="form-control" placeholder={mastodon ? labels.tag : 'or search by tag'} value={tagInput} onChange={(event) => setTagInput(event.target.value)} />
                  <button type="submit" className="btn btn-sm btn-outline-secondary">{mastodon ? labels.search : 'Search'}</button>
                </form>

                <div className="photo-picker-grid" aria-busy={loading}>
                  {data.photos.map((photo) => (
                    <button key={photo.id} type="button" className="photo-picker-photo" title={photo.title} disabled={loading} onClick={() => {setChosen(photo); setLicenseAccepted(false);}}>
                      <img src={photo.thumb_url} alt={photo.title || 'Untitled photo'} loading="lazy" />
                    </button>
                  ))}
                </div>
                {data.photos.length === 0 && (
                  <p className="photo-picker-hint">{mastodon ? labels.empty : <>No photos found{filters.tag ? ` tagged “${filters.tag}”` : ''}.</>}</p>
                )}

                {mastodon && (
                  <div className="photo-picker-pager">
                    {filters.cursor && <button type="button" className="btn btn-sm btn-outline-secondary" disabled={loading} onClick={() => setFilters({...filters, cursor: null})}>{labels.recent}</button>}
                    {data.next_cursor && <button type="button" className="btn btn-sm btn-outline-secondary" disabled={loading} onClick={() => setFilters({...filters, cursor: data.next_cursor})}>{labels.more}</button>}
                  </div>
                )}

                {data.total_pages > 1 && (
                  <div className="photo-picker-pager">
                    <button type="button" className="btn btn-sm btn-outline-secondary" disabled={loading || data.page <= 1} onClick={() => setFilters({...filters, page: data.page - 1})}>Previous</button>
                    <span>Page {data.page} of {data.total_pages}</span>
                    <button type="button" className="btn btn-sm btn-outline-secondary" disabled={loading || data.page >= data.total_pages} onClick={() => setFilters({...filters, page: data.page + 1})}>Next</button>
                  </div>
                )}
              </div>
            )}

            {ready && chosen && (
              <>
                {errors.length > 0 && (
                  <div className="alert alert-danger" role="alert">
                    <i className="fas fa-exclamation-triangle" aria-hidden="true" />{' '}
                    <strong>That didn&rsquo;t work.</strong>
                    <ul className="mb-0">{errors.map((message) => <li key={message}>{message}</li>)}</ul>
                    <span>Your choice is kept, so you can press Add photo to try again.</span>
                  </div>
                )}
                <div className="crop-confirm">
                  <p className="crop-confirm-label">Ready to add this photo?</p>
                  <dl className="crop-confirm-details photo-picker-confirm">
                    <dt>To</dt>
                    <dd>{label}</dd>
                    <dt>Photo</dt>
                    <dd>
                      <img src={chosen.preview_url} alt={chosen.title || 'The photo you chose'} className="photo-picker-preview" />
                      <span className="photo-picker-title">{chosen.title}</span>
                      <button type="button" className="btn btn-sm btn-outline-secondary ms-3" onClick={() => setChosen(null)} disabled={saving}>
                        <i className="fas fa-edit" aria-hidden="true" /> Change<span className="visually-hidden"> photo</span>
                      </button>
                    </dd>
                  </dl>
                  <p className="photo-picker-hint mb-0">{mastodon ? labels.hosted : 'The photo stays on Flickr. Growstuff shows it and links back to it.'}</p>
                  {needsLicense && (
                    <div className="mt-3">
                      <label className="form-check">
                        <input type="checkbox" className="form-check-input" checked={licenseAccepted} onChange={(event) => setLicenseAccepted(event.target.checked)} disabled={saving} required />
                        <span className="form-check-label">{labels.license_consent}</span>
                      </label>
                      <p className="photo-picker-hint">{labels.license_hint} <a href="https://creativecommons.org/licenses/by-sa/4.0/" target="_blank" rel="noopener noreferrer">{labels.license_link}</a></p>
                    </div>
                  )}
                  {mastodon && chosen.license_name && <p>{chosen.license_name}</p>}
                </div>
              </>
            )}
          </div>
          {ready && chosen && (
            <div className="modal-footer">
              <button type="button" className="btn btn-link" onClick={() => setChosen(null)} disabled={saving}>{mastodon ? labels.back : 'Back'}</button>
              <button type="button" className="btn btn-success btn-plant" onClick={add} disabled={saving || (needsLicense && !licenseAccepted)} aria-busy={saving} autoFocus>
                {saving ? <><i className="fas fa-spinner fa-spin" aria-hidden="true" /> Adding…</> : mastodon ? labels.add : 'Add photo'}
              </button>
            </div>
          )}
        </>
      )}
    </Modal>
  );
}
