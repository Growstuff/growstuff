import React, {useState} from 'react';

import {getJson, patchJson} from '../api';
import Modal from './Modal';
import PickerButton from './PickerButton';

function searchMessage(status) {
  if (status === 401) return 'Please sign in again to set your location.';
  return 'We couldn\'t search for places just now. Please try again.';
}

const DEFAULT_TITLE = 'Tell us where you garden';
const DEFAULT_INTRO = 'We use this to match advice to your season and latitude, and to show you what gardeners near you are doing. Your city or region is public, like everything else you record.';

// A button that opens a dialog for saying where you garden: search for a city
// or region and pick the right one, or use the browser's location. Choosing
// saves it and reloads the page, so the season, suggestions and neighbours
// all follow from it.
//
// Searches run when asked, not as you type: our place search (Nominatim)
// asks that clients don't autocomplete.
//
// Pass displayId to show the saved place in that element and stay on the page, for a page whose form may hold unsaved edits.
//
// It also sets where a garden is: pass the garden's saveUrl, its own title and
// intro, and the member's own place as profilePlace to offer it ready to save.
export default function LocationPicker({label, buttonClass, searchUrl, saveUrl, title = DEFAULT_TITLE, intro = DEFAULT_INTRO, profilePlace = null, displayId = null}) {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState('');
  const [places, setPlaces] = useState(null); // null: not searched yet
  const [chosen, setChosen] = useState(null);
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState('');

  function close() {
    setOpen(false);
    setPlaces(null);
    setChosen(null);
    setMessage('');
  }

  async function lookup(params) {
    setBusy(true);
    setMessage('');
    setChosen(null);
    try {
      const {ok, status, data} = await getJson(`${searchUrl}?${params}`);
      if (!ok) {
        setPlaces(null);
        setMessage(searchMessage(status));
        return;
      }
      setPlaces(data);
      if (data.length === 1) setChosen(data[0]);
    } catch (error) {
      setMessage(searchMessage());
    } finally {
      setBusy(false);
    }
  }

  function chooseProfilePlace() {
    setMessage('');
    setPlaces([profilePlace]);
    setChosen(profilePlace);
  }

  function search(event) {
    event.preventDefault();
    if (query.trim().length < 2) {
      setMessage('Type a city or region to search for.');
      return;
    }
    lookup(new URLSearchParams({q: query.trim()}));
  }

  function useMyLocation() {
    if (!navigator.geolocation) {
      setMessage('Your browser can\'t share its location. Search for your city instead.');
      return;
    }
    setBusy(true);
    setMessage('');
    navigator.geolocation.getCurrentPosition(
      (position) => lookup(new URLSearchParams({lat: position.coords.latitude, lng: position.coords.longitude})),
      () => {
        setBusy(false);
        setMessage('We couldn\'t get your location. Search for your city instead.');
      },
      {timeout: 10000}
    );
  }

  async function save() {
    setBusy(true);
    setMessage('');
    try {
      const {ok} = await patchJson(saveUrl, {location: {name: chosen.name, latitude: chosen.latitude, longitude: chosen.longitude}});
      if (!ok) throw new Error('save failed');
      const display = displayId && document.getElementById(displayId);
      if (display) {
        // Inside a form with other edits waiting, so show the place here rather than reloading.
        display.textContent = chosen.name;
        close();
        setBusy(false);
      } else {
        window.location.reload();
      }
    } catch (error) {
      setBusy(false);
      setMessage('Something went wrong saving that. Please try again.');
    }
  }

  return (
    <>
      <PickerButton label={label} className={buttonClass} onClick={() => setOpen(true)} />
      {open && (
        <Modal title={title} titleId="location-picker-title" onClose={close}>
          <div className="modal-body">
            <p className="text-muted">{intro}</p>
            {profilePlace && (
              <p className="mb-2">
                <button type="button" className="btn btn-outline-success btn-sm" onClick={chooseProfilePlace} disabled={busy}>
                  Use {profilePlace.name} from my profile
                </button>
              </p>
            )}
            <form onSubmit={search} role="search">
              <label htmlFor="location-picker-query" className="form-label">City or region</label>
              <div className="input-group">
                <input
                  id="location-picker-query"
                  type="search"
                  className="form-control"
                  value={query}
                  placeholder="For example, Wellington"
                  autoComplete="off"
                  onChange={(event) => setQuery(event.target.value)}
                />
                <button type="submit" className="btn btn-success" disabled={busy}>Search</button>
              </div>
            </form>
            <p className="my-2">
              <button type="button" className="btn btn-link p-0" onClick={useMyLocation} disabled={busy}>
                Use my current location
              </button>
            </p>

            <div aria-live="polite" className="location-picker-status">
              {busy && <span className="text-muted">Looking…</span>}
              {message && <span className="text-danger">{message}</span>}
              {places && places.length === 0 && !busy && !message && (
                <span className="text-muted">We couldn't find that. Try a nearby city, or a region.</span>
              )}
            </div>

            {places && places.length > 0 && (
              <fieldset className="location-picker-results">
                <legend className="visually-hidden">Places found</legend>
                {places.map((place) => (
                  <label key={`${place.latitude},${place.longitude}`} className="location-picker-place">
                    <input
                      type="radio"
                      name="location-picker-place"
                      checked={chosen === place}
                      onChange={() => setChosen(place)}
                    />
                    <span>{place.name}</span>
                  </label>
                ))}
              </fieldset>
            )}
          </div>
          <div className="modal-footer">
            <button type="button" className="btn btn-secondary" onClick={close}>Cancel</button>
            <button type="button" className="btn btn-success" onClick={save} disabled={!chosen || busy}>
              Save location
            </button>
          </div>
        </Modal>
      )}
    </>
  );
}
