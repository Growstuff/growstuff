import React, {useCallback, useEffect, useRef, useState} from 'react';

import {getJson, postJson} from '../api';
import Modal from './Modal';
import Steps from './Steps';

// Flickr's own sign-in can't be shown inside the dialog, so it opens in a small
// window, and lands on a page that closes itself (see AuthenticationsController#connected).
const CONNECT_URL = `/members/auth/flickr?origin=${encodeURIComponent('/authentications/connected')}`;
const POLL_MS = 2000;

function errorMessages(status, data) {
  if (status === 422 && data && data.errors) {
    const messages = Object.entries(data.errors).flatMap(([field, list]) => list.map((m) => `${field.replace(/_/g, ' ').replace(/^./, (c) => c.toUpperCase())} ${m}`));
    if (messages.length > 0) return messages;
  }
  if (status === 401) return ['Please sign in again to add this photo.'];
  return ['Something went wrong adding that photo. Please try again.'];
}

// Adding a photo to a planting or garden, as a dialog over the garden list. The
// photos are the member's own, from Flickr, so if Flickr isn't connected (or the
// connection has expired) the first step connects it, here, in a pop-up; the dialog
// notices when that has happened. Then choose a photo (by album or tag, a page at a
// time), confirm it, and it is added and the garden's card refreshed, so the page
// is never left. `newUrl` is the menu item's own link, /photos/new?type=..&id=...
export default function AddPhotoModal({label, newUrl, iconUrl, onClose, onAdded}) {
  const target = new URL(newUrl, window.location.origin).searchParams;
  const type = target.get('type');
  const id = target.get('id');

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
  const popup = useRef(null);

  const load = useCallback(async (next, signal) => {
    const query = new URLSearchParams({type, id});
    if (next.set) query.set('set', next.set);
    if (next.tag) query.set('tag', next.tag);
    if (next.page > 1) query.set('page', next.page);
    const {ok, data: result} = await getJson(`/photos/new.json?${query}`, {signal});
    if (!ok) throw new Error('load failed');
    return result;
  }, [type, id]);

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
    popup.current = window.open(CONNECT_URL, 'flickr-connect', 'width=640,height=760');
    setBlocked(!popup.current);
    setWaiting(true);
  }

  function search(event) {
    event.preventDefault();
    setFilters({set: '', tag: tagInput.trim(), page: 1});
  }

  function chooseAlbum(event) {
    setTagInput('');
    setFilters({set: event.target.value, tag: '', page: 1});
  }

  async function add() {
    setSaving(true);
    setErrors([]);
    try {
      const {ok, status, data: result} = await postJson(`/photos.json?type=${encodeURIComponent(type)}&id=${encodeURIComponent(id)}`, {
        photo: {source_id: chosen.id, source: 'flickr'},
      });
      if (ok) {
        onAdded(result); // closes this dialog
        return;
      }
      setErrors(errorMessages(status, result));
    } catch (error) {
      setErrors(['Couldn\'t reach the server. Please try again.']);
    }
    setSaving(false);
  }

  const ready = data && data.state === 'ready';
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
        <div className="modal-body">
          <div className="alert alert-danger mb-0" role="alert">Couldn&rsquo;t load your photos. Please close this and try again.</div>
        </div>
      )}
      {!loadError && !data && (
        <div className="modal-body plant-dialog-loading" role="status">
          <span>
            <i className="fa fa-spinner fa-spin" aria-hidden="true" /> Loading…
          </span>
        </div>
      )}
      {data && (
        <>
          <div className="modal-body plant-dialog-body">
            <Steps steps={steps} current={current} />

            {!ready && (
              <div className="crop-picker">
                <h3 className="crop-picker-label">{data.state === 'reconnect' ? 'Reconnect Flickr' : 'Connect your Flickr account'}</h3>
                <p>
                  Photos on Growstuff are shared from Flickr, so you choose them from your own photos there.{' '}
                  {data.state === 'reconnect' ? 'Your connection has expired, or been taken back on Flickr.' : 'Connect your account and you can choose one here.'}{' '}
                  Growstuff only reads your photos.
                </p>
                <button type="button" className="btn btn-success btn-plant" onClick={connect} disabled={waiting} autoFocus>
                  <i className="fab fa-flickr" aria-hidden="true" /> {data.state === 'reconnect' ? 'Reconnect Flickr' : 'Connect Flickr'}
                </button>
                {waiting && (
                  <div className="photo-picker-waiting" role="status">
                    <i className="fa fa-spinner fa-spin" aria-hidden="true" />{' '}
                    {blocked ? 'Your browser blocked the window.' : 'Waiting for you to allow access on Flickr…'}{' '}
                    {blocked && <a href={CONNECT_URL} target="_blank" rel="noopener noreferrer">Connect in a new tab</a>}
                    {!blocked && <span className="photo-picker-hint">This picks up on its own once you have.</span>}
                  </div>
                )}
              </div>
            )}

            {ready && !chosen && (
              <div className="photo-picker">
                <p className="photo-picker-hint">
                  Connected to Flickr as <a href={data.profile_url} target="_blank" rel="noopener noreferrer">{data.name}</a>.
                  {' '}Choose a photo.
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
                  <label className="visually-hidden" htmlFor="add-photo-tag">Search by tag</label>
                  <input id="add-photo-tag" type="search" className="form-control" placeholder="or search by tag" value={tagInput} onChange={(event) => setTagInput(event.target.value)} />
                  <button type="submit" className="btn btn-sm btn-outline-secondary">Search</button>
                </form>

                <div className="photo-picker-grid" aria-busy={loading}>
                  {data.photos.map((photo) => (
                    <button key={photo.id} type="button" className="photo-picker-photo" title={photo.title} onClick={() => setChosen(photo)}>
                      <img src={photo.thumb_url} alt={photo.title || 'Untitled photo'} loading="lazy" />
                    </button>
                  ))}
                </div>
                {data.photos.length === 0 && (
                  <p className="photo-picker-hint">No photos found{filters.tag ? ` tagged “${filters.tag}”` : ''}.</p>
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
                    <i className="fa fa-exclamation-triangle" aria-hidden="true" />{' '}
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
                        <i className="fa fa-edit" aria-hidden="true" /> Change<span className="visually-hidden"> photo</span>
                      </button>
                    </dd>
                  </dl>
                  <p className="photo-picker-hint mb-0">The photo stays on Flickr. Growstuff shows it and links back to it.</p>
                </div>
              </>
            )}
          </div>
          {ready && chosen && (
            <div className="modal-footer">
              <button type="button" className="btn btn-link" onClick={() => setChosen(null)} disabled={saving}>Back</button>
              <button type="button" className="btn btn-success btn-plant" onClick={add} disabled={saving} aria-busy={saving} autoFocus>
                {saving ? <><i className="fa fa-spinner fa-spin" aria-hidden="true" /> Adding…</> : 'Add photo'}
              </button>
            </div>
          )}
        </>
      )}
    </Modal>
  );
}
