import React from 'react';

import {isPlainClick} from '../events';
import ActionsMenu from './ActionsMenu';
import CropChip from './CropChip';
import PlantedDate from './PlantedDate';

// One annual planting as a row of three aligned columns: the crop (and when it
// was planted), how it is getting on (badges, then a progress bar or a note
// when there is nothing to predict from), and its own actions menu.
export default function PlantingRow({planting, defaultIconUrl, highlighted, onUpdated, onEdit}) {
  const {id, url, crop, badges} = planting;

  return (
    <div className={`planting-row${highlighted ? ' planting-just-added' : ''}`}>
      <div className="planting-row-crop">
        <CropChip url={url} crop={crop} defaultIconUrl={defaultIconUrl} highlighted={highlighted} />
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
          <Progress percentage={planting.percentage_grown} state={planting.progress_state} finishLabel={planting.finish_predicted_label} />
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
            if (action.key === 'edit' && onEdit && isPlainClick(event)) {
              event.preventDefault();
              onEdit(planting);
            }
          }}
        />
      </div>
    </div>
  );
}

function Progress({percentage, state, finishLabel}) {
  if (percentage === null || percentage === undefined) return null;

  return (
    <div className="planting-progress">
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
      <div className="planting-progress-labels">
        <span>{Math.round(percentage)}%</span>
        {finishLabel && <span>{finishLabel}</span>}
      </div>
    </div>
  );
}
