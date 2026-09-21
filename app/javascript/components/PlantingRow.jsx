import React from 'react';

import {formatDate} from '../dates';
import {isPlainClick} from '../events';
import ActionsMenu from './ActionsMenu';
import CropChip from './CropChip';
import PlantedDate from './PlantedDate';

// One annual planting as a row of three aligned columns: the crop (and when it
// was planted), how it is getting on (badges, then a progress bar or a note
// when there is nothing to predict from), and its own actions menu.
export default function PlantingRow({planting, defaultIconUrl, highlighted, highlightKind = 'added', onUpdated, onEdit, onHarvest, onSaveSeeds, onAddPhoto}) {
  const {id, url, crop, badges} = planting;

  return (
    <div className={`planting-row${highlighted ? ` planting-just-${highlightKind}` : ''}`}>
      <div className="planting-row-crop">
        <div className="planting-row-chip">
          <CropChip url={url} crop={crop} defaultIconUrl={defaultIconUrl} highlighted={highlighted && highlightKind === 'added'} />
          {highlighted && highlightKind === 'harvested' && (
            <span className="harvest-recorded-tag"><i className="fa fa-check" aria-hidden="true" /> Harvest recorded</span>
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
      <div className="planting-row-actions">
        <ActionsMenu
          id={`planting-${id}`}
          actions={planting.actions}
          label={<i className="fa fa-ellipsis-v" aria-hidden="true" />}
          ariaLabel={`Actions for ${crop.name}`}
          className="btn btn-sm btn-link actions-toggle-dots"
          onSelect={(action, event) => {
            const open = {edit: onEdit, harvest: onHarvest, seeds: onSaveSeeds, photo: onAddPhoto}[action.key];
            if (open && isPlainClick(event)) {
              event.preventDefault();
              open(planting, action);
            }
          }}
        />
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
