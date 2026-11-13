import React, {useState} from 'react';

// A button that asks the browser where the visitor is and reloads the page with it, so the server can show the nearest weather
// we hold. The position is rounded to the weather grid and goes in the address, so nothing is stored. url is the page's address and
// labels are the words, from the server.
export default function UseMyLocation({url, labels}) {
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState('');

  function find() {
    if (!navigator.geolocation) {
      setMessage(labels.unsupported);
      return;
    }
    setBusy(true);
    setMessage('');
    navigator.geolocation.getCurrentPosition(
      ({coords}) => {
        const params = new URLSearchParams({lat: coords.latitude.toFixed(2), lng: coords.longitude.toFixed(2)});
        window.location.assign(`${url}?${params}`);
      },
      () => {
        setBusy(false);
        setMessage(labels.failed);
      },
      {timeout: 10000}
    );
  }

  return (
    <div>
      <button type="button" className="btn btn-success" disabled={busy} onClick={find}>
        <i className={`fas ${busy ? 'fa-globe fa-spin' : 'fa-location-crosshairs'} me-1`} aria-hidden="true" />
        {busy ? labels.finding : labels.button}
      </button>
      {message && <p className="text-muted mt-2 mb-0" role="alert">{message}</p>}
    </div>
  );
}
