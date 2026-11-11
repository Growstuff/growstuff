import React, {useState} from 'react';

import {csrfToken, postJson} from '../api';

// A crop suggested for a season, as the home page shows its suggestions: its photo, name, notes (the temperatures it likes and
// how long it takes), whether the member is growing it, grew it in earlier years or someone they follow is growing it, a button that adds a job to plant it to the
// planned jobs, and a way to say it is not for them.
//
// Adding is sent without leaving the page. Once the crop is in the planned jobs for the season, which the server says in
// crop.planned and onPlanned passes on, the photo has a tick and the button says so.
export default function SuggestedCropCard({crop, season, urls, labels, onPlanned}) {
  const [adding, setAdding] = useState(false);
  const [failed, setFailed] = useState(false);

  async function add() {
    setAdding(true);
    setFailed(false);
    try {
      const {ok} = await postJson(urls.jobs, {crop_id: crop.id, season});
      if (!ok) throw new Error('Could not add');
      onPlanned(crop.id);
    } catch (error) {
      setFailed(true);
    } finally {
      setAdding(false);
    }
  }

  return (
    <div className="home-crop">
      <a href={crop.path}>
        <span className="home-crop-photo">
          <img src={crop.image} alt={crop.name} loading="lazy" />
          {crop.planned && (
            <span className="home-crop-tick" title={labels.planned}>
              <i className="fas fa-check" aria-hidden="true" />
              <span className="visually-hidden">{labels.planned}</span>
            </span>
          )}
        </span>
        <span className="home-crop-name">{crop.name}</span>
        {crop.note && <span className="home-crop-note">{crop.note}</span>}
        {crop.timing && <span className="home-crop-note">{crop.timing}</span>}
      </a>
      {crop.growing && (
        <span className="home-crop-flag">
          <i className="fas fa-seedling" aria-hidden="true" /> {labels.growing}
        </span>
      )}
      {crop.grown_before && (
        <span className="home-crop-flag home-crop-flag--past">
          <i className="fas fa-clock-rotate-left" aria-hidden="true" /> {crop.grown_before}
        </span>
      )}
      {crop.followed && <span className="home-crop-flag home-crop-flag--followed">{crop.followed}</span>}
      {crop.planned ? (
        <a className="home-crop-go home-crop-planned" href={urls.planned}>
          <i className="fas fa-check" aria-hidden="true" /> {labels.planned}
        </a>
      ) : (
        <button type="button" className="home-crop-go" disabled={adding} onClick={add}>
          {adding && <span className="spinner-border spinner-border-sm me-1" aria-hidden="true" />}
          {labels.addToJobs}
        </button>
      )}
      {failed && <span className="home-crop-flag home-crop-flag--failed" role="alert">{labels.addFailed}</span>}
      <form className="home-dismiss-form" method="post" action={urls.dismiss}>
        <input type="hidden" name="authenticity_token" value={csrfToken()} />
        <input type="hidden" name="crop_id" value={crop.id} />
        <button type="submit" className="home-crop-dismiss">{labels.notForMe}</button>
      </form>
    </div>
  );
}
