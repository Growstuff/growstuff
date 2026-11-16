import React, {useEffect, useRef, useState} from 'react';

import {getJson} from '../api';
import SuggestedCropCard from './SuggestedCropCard';

// The member's climate through the year as an accordion with a row for each season. A row shows the season's figures and
// opens to the crops for it, which are fetched when it is first opened, with a spinner while they come. The season in progress
// comes with the page, already open.
//
// seasons: each as { name, title, current, hasData, months, mean, figures: [{label, value}], url } with its text ready.
// initial: { season name => its crops, as the season's url answers }. open: the name of the season open first.
// enabled: whether crops are suggested at all. guest: a visitor who isn't signed in, whose cards leave out the buttons that need an account.
// urls and labels are the addresses and words, from the server.
export default function SeasonSuggestions({seasons, open: firstOpen, initial = {}, enabled, guest = false, urls, labels}) {
  const [open, setOpen] = useState(firstOpen);
  const [crops, setCrops] = useState(initial);
  const [status, setStatus] = useState({}); // season name => 'loading' or 'failed'
  const opened = useRef(false);

  // A season the member opens is brought to the top of the window, as the one that was open above it closes and moves it down.
  // The one open when the page loads stays where it is.
  useEffect(() => {
    if (!opened.current) {
      opened.current = true;
      return;
    }
    if (!open) return;
    const reduced = window.matchMedia?.('(prefers-reduced-motion: reduce)').matches;
    document.getElementById(`season-item-${open}`)?.scrollIntoView?.({behavior: reduced ? 'auto' : 'smooth', block: 'start'});
  }, [open]);

  async function load(season) {
    setStatus((now) => ({...now, [season.name]: 'loading'}));
    try {
      const {ok, data} = await getJson(season.url);
      if (!ok || !data) throw new Error('Could not load');
      setCrops((now) => ({...now, [season.name]: data}));
      setStatus((now) => ({...now, [season.name]: undefined}));
    } catch (error) {
      setStatus((now) => ({...now, [season.name]: 'failed'}));
    }
  }

  // The crop is in the planned jobs for the season now: say so wherever it is listed there.
  function markPlanned(seasonName, cropId) {
    setCrops((now) => ({
      ...now,
      [seasonName]: {
        ...now[seasonName],
        groups: now[seasonName].groups.map((group) => ({
          ...group,
          crops: group.crops.map((crop) => (crop.id === cropId ? {...crop, planned: true} : crop)),
        })),
      },
    }));
  }

  function toggle(season) {
    const closing = open === season.name;
    setOpen(closing ? null : season.name);
    if (!closing && enabled && season.hasData && !crops[season.name] && status[season.name] !== 'loading') load(season);
  }

  return (
    <div className="accordion season-accordion">
      {seasons.map((season) => (
        <Season
          key={season.name}
          season={season}
          expanded={open === season.name}
          onToggle={() => toggle(season)}
          labels={labels}
        >
          <Crops
            season={season}
            enabled={enabled}
            data={crops[season.name]}
            status={status[season.name]}
            onRetry={() => load(season)}
            onPlanned={(cropId) => markPlanned(season.name, cropId)}
            guest={guest}
            urls={urls}
            labels={labels}
          />
        </Season>
      ))}
    </div>
  );
}

function Season({season, expanded, onToggle, labels, children}) {
  const panel = `season-${season.name}`;
  const classes = ['accordion-item', `season-item--${season.name}`, season.current && 'season-item--current'];
  return (
    <div id={`season-item-${season.name}`} className={classes.filter(Boolean).join(' ')}>
      <h3 className="accordion-header">
        <button
          type="button"
          className={`accordion-button${expanded ? '' : ' collapsed'}`}
          aria-expanded={expanded}
          aria-controls={panel}
          onClick={onToggle}
        >
          <span className="season-summary">
            <span className="season-summary-name">
              <i className={`fas fa-${season.icon} season-icon me-2`} aria-hidden="true" />
              {season.title}
              {season.current && <span className="badge text-bg-light align-middle ms-1">{labels.now}</span>}
              <small className="season-summary-months">{season.months}</small>
            </span>
            {season.hasData ? (
              <>
                <span className="season-summary-mean">
                  <strong>{season.mean}</strong>
                  <small>{labels.average}</small>
                </span>
                <dl className="season-summary-figures">
                  {season.figures.map((figure) => (
                    <div key={figure.label}>
                      <dt>{figure.label}</dt>
                      <dd>{figure.value}</dd>
                    </div>
                  ))}
                </dl>
              </>
            ) : (
              <span className="text-muted">{labels.noData}</span>
            )}
          </span>
        </button>
      </h3>
      <div id={panel} className={`accordion-collapse collapse${expanded ? ' show' : ''}`}>
        <div className="accordion-body">{expanded && children}</div>
      </div>
    </div>
  );
}

function Crops({season, enabled, guest, data, status, onRetry, onPlanned, urls, labels}) {
  if (!season.hasData) return <p className="text-muted">{labels.noData}</p>;
  if (!enabled) return <p className="text-muted">{labels.off}</p>;
  if (status === 'failed') {
    return (
      <p role="alert">
        {labels.loadFailed}{' '}
        <button type="button" className="btn btn-link p-0 align-baseline" onClick={onRetry}>{labels.retry}</button>
      </p>
    );
  }
  if (!data) {
    return (
      <div className="season-loading" role="status">
        {guest ? <i className="fas fa-globe fa-spin text-success" aria-hidden="true" /> : <span className="spinner-border text-success" aria-hidden="true" />}
        <span>{labels.loading}</span>
      </div>
    );
  }
  return data.groups.map((group) => (
    <div key={group.key}>
      <h4 className="season-crops-heading">{group.heading}</h4>
      {group.crops.length ? (
        <div className="home-crops">
          {group.crops.map((crop) => (
            <SuggestedCropCard key={crop.id} crop={crop} season={season.name} guest={guest} urls={urls} labels={labels} onPlanned={onPlanned} />
          ))}
        </div>
      ) : (
        <p className="text-muted">{labels.noCrops}</p>
      )}
    </div>
  ));
}
