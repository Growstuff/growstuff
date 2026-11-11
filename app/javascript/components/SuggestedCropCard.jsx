import React from 'react';

import {csrfToken} from '../api';

// A crop suggested for a season, as the home page shows its suggestions: its photo, name, notes (the temperatures it likes and
// how long it takes), whether the member is growing it or someone they follow is, a button that adds a job to
// plant it to the planned jobs (or says it is there already), and a way to say it is not for them. Both buttons send a form and
// come back to the suggestions with the season open.
export default function SuggestedCropCard({crop, season, urls, labels}) {
  return (
    <div className="home-crop">
      <a href={crop.path}>
        <img src={crop.image} alt={crop.name} loading="lazy" />
        <span className="home-crop-name">{crop.name}</span>
        {crop.note && <span className="home-crop-note">{crop.note}</span>}
        {crop.timing && <span className="home-crop-note">{crop.timing}</span>}
      </a>
      {crop.growing && (
        <span className="home-crop-flag">
          <i className="fas fa-seedling" aria-hidden="true" /> {labels.growing}
        </span>
      )}
      {crop.followed && <span className="home-crop-flag home-crop-flag--followed">{crop.followed}</span>}
      {crop.planned ? (
        <a className="home-crop-go home-crop-planned" href={urls.planned}>{labels.planned}</a>
      ) : (
        <CropForm action={urls.jobs} crop={crop} season={season} className="home-crop-go" label={labels.addToJobs} />
      )}
      <CropForm action={urls.dismiss} crop={crop} className="home-crop-dismiss" label={labels.notForMe} />
    </div>
  );
}

function CropForm({action, crop, season, className, label}) {
  return (
    <form className="home-dismiss-form" method="post" action={action}>
      <input type="hidden" name="authenticity_token" value={csrfToken()} />
      <input type="hidden" name="crop_id" value={crop.id} />
      {season && <input type="hidden" name="season" value={season} />}
      <button type="submit" className={className}>{label}</button>
    </form>
  );
}
