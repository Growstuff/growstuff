import React, {useEffect, useState} from 'react';

const WAITING_MS = 2500;
// The browser's reasons for failing (GeolocationPositionError.code), and the label that says each.
const FAILURES = {1: 'denied', 2: 'unavailable', 3: 'timeout'};
// Long enough for someone to answer the browser's permission question; an answer from the last ten minutes will do.
const OPTIONS = {timeout: 30000, maximumAge: 600000};

// A button that asks the browser where the visitor is and reloads the page with it, so the server can show the nearest weather
// we hold. The position is rounded to the weather grid and goes in the address, so nothing is stored. url is the page's address and
// labels are the words, from the server: denied, unavailable and timeout say why it failed, and waiting is a list of light-hearted lines shown in turn while it works.
export default function UseMyLocation({url, labels}) {
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState('');
  const [waiting, setWaiting] = useState(0);

  useEffect(() => {
    if (!busy) return undefined;
    const timer = setInterval(() => setWaiting((now) => now + 1), WAITING_MS);
    return () => clearInterval(timer);
  }, [busy]);

  function find() {
    if (!navigator.geolocation) {
      setMessage(labels.unsupported);
      return;
    }
    setBusy(true);
    setWaiting(0);
    setMessage('');
    navigator.geolocation.getCurrentPosition(
      ({coords}) => {
        const params = new URLSearchParams({lat: coords.latitude.toFixed(2), lng: coords.longitude.toFixed(2)});
        window.location.assign(`${url}?${params}`);
      },
      (error) => {
        setBusy(false);
        setMessage(labels[FAILURES[error.code]] || labels.failed);
      },
      OPTIONS
    );
  }

  return (
    <div>
      <button type="button" className="btn btn-success" disabled={busy} onClick={find}>
        <i className={`fas ${busy ? 'fa-globe fa-spin' : 'fa-location-crosshairs'} me-1`} aria-hidden="true" />
        {busy ? labels.finding : labels.button}
      </button>
      {busy && labels.waiting?.length > 0 && (
        <p className="text-muted mt-2 mb-0" role="status">{labels.waiting[waiting % labels.waiting.length]}</p>
      )}
      {message && <p className="text-muted mt-2 mb-0" role="alert">{message}</p>}
    </div>
  );
}
