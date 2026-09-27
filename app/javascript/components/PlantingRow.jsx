import React from 'react';

import {formatDate} from '../dates';
import PlantedDate from './PlantedDate';
import PlantingChip from './PlantingChip';

// One annual planting as a row of two aligned columns: the crop, which is also
// the planting's menu (and when it was planted), and how it is getting on
// (badges, then a progress bar or a note when there is nothing to predict from).
// `handlers` is what the menu's items open (see selectPlantingAction).
export default function PlantingRow({planting, defaultIconUrl, highlighted, highlightKind = 'added', onUpdated, handlers}) {
  const {badges} = planting;

  return (
    <div className={`planting-row${highlighted ? ` planting-just-${highlightKind}` : ''}`}>
      <div className="planting-row-crop">
        <div className="planting-row-chip">
          <PlantingChip planting={planting} defaultIconUrl={defaultIconUrl} highlighted={highlighted && highlightKind === 'added'} handlers={handlers} />
          {highlighted && highlightKind === 'harvested' && (
            <span className="harvest-recorded-tag"><i className="fas fa-check" aria-hidden="true" /> Harvest recorded</span>
          )}
        </div>
        <PlantedDate planting={planting} onUpdated={onUpdated} />
      </div>
      <div className="planting-row-status">
        {badges.length > 0 && (
          <div className="planting-badges">
            {badges.map((badge) => (
              <span key={badge.kind} className={`badge text-bg-info badge-${badge.kind.replace('_', '-')}`} title={badge.title}>
                {badge.label}
              </span>
            ))}
          </div>
        )}
        {planting.progress_note ? (
          <small className="planting-row-note">{planting.progress_note}</small>
        ) : (
          <Progress percentage={planting.percentage_grown} state={planting.progress_state} finishLabel={planting.finish_predicted_label} harvests={planting.harvests} />
        )}
      </div>
    </div>
  );
}

// The bar, with a tick at the date of each harvest, on the bar's own scale.
// The ticks are for the eye; the hidden sentence is for everything else.
function Progress({percentage, state, finishLabel, harvests = []}) {
  if (percentage === null || percentage === undefined) return null;

  const last = harvests[harvests.length - 1];

  return (
    <div className="planting-progress">
      <div className="planting-progress-track">
        <div className="progress">
          <div
            className={`progress-bar progress-bar--${state}`}
            role="progressbar"
            aria-valuemin="0"
            aria-valuemax="100"
            aria-valuenow={percentage}
            style={{width: `${percentage}%`}}
          />
        </div>
        {harvests.map((harvest, index) => (
          <span
            key={`${harvest.date}-${index}`}
            className="harvest-tick"
            style={{left: `${harvest.percent}%`}}
            title={`Harvested ${formatDate(harvest.date)}`}
          />
        ))}
      </div>
      {last && (
        <span className="visually-hidden">
          {harvests.length} {harvests.length === 1 ? 'harvest' : 'harvests'}, the latest on {formatDate(last.date)}
        </span>
      )}
      <div className="planting-progress-labels">
        <span>{Math.round(percentage)}%</span>
        {finishLabel && <span>{finishLabel}</span>}
      </div>
    </div>
  );
}
