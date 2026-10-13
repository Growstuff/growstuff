import React, {useState} from 'react';

import {getJson} from '../api';

// "Show earlier days" for the friends and neighbours feed: fetches the next
// small chunk of it, already rendered by Rails, and adds it below, so the page
// never loads more than a few days at a time. `url` is where the next chunk is;
// each reply says where the one after it is, until there is none.
export default function FeedMore({url, label}) {
  const [chunks, setChunks] = useState([]);
  const [next, setNext] = useState(url);
  const [busy, setBusy] = useState(false);

  async function load() {
    setBusy(true);
    try {
      const {ok, data} = await getJson(next);
      if (ok && data) {
        setChunks((existing) => [...existing, data.html]);
        setNext(data.next);
      }
    } finally {
      setBusy(false);
    }
  }

  return (
    <>
      {chunks.map((html, index) => <div key={index} dangerouslySetInnerHTML={{__html: html}} />)}
      {next && (
        <p className="text-center">
          <button type="button" className="btn btn-success" disabled={busy} onClick={load}>{label}</button>
        </p>
      )}
    </>
  );
}
