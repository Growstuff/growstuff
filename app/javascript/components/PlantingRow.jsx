import React from 'react';

import ActionsMenu from './ActionsMenu';
import CropChip from './CropChip';

// One annual planting: crop, badges, progress bar and quick actions.
// Matches plantings/_progress_list and its partials.
export default function PlantingRow({planting, defaultIconUrl, highlighted}) {
  const {id, url, crop, badges, percentage_grown: percentage, finish_predicted_label: finishLabel} = planting;

  return (
    <div className={`row progress-row${highlighted ? ' planting-just-added' : ''}`}>
      <div className="col-12 col-md-4 progress-row--crop">
        <CropChip url={url} crop={crop} defaultIconUrl={defaultIconUrl} highlighted={highlighted} />
        <div className="planting-badges">
          {badges.map((badge) => (
            <span
              key={badge.kind}
              className={`badge badge-info badge-${badge.kind.replace('_', '-')}`}
              title={badge.title}
            >
              {badge.label}
            </span>
          ))}
        </div>
      </div>
      <div className="col-12 col-md-6 progress-row--bar">
        {planting.progress_note ? (
          <small>{planting.progress_note}</small>
        ) : (
          <Progress percentage={percentage} finishLabel={finishLabel} />
        )}
      </div>
      <div className="col-12 col-md-2">
        <ActionsMenu
          id={`planting-${id}`}
          actions={planting.actions}
          label=""
          ariaLabel={`Actions for ${crop.name}`}
          className="nav-link dropdown-toggle"
        />
      </div>
    </div>
  );
}

function Progress({percentage, finishLabel}) {
  if (percentage === null || percentage === undefined) return null;

  return (
    <>
      <div className="progress">
        <div
          className="progress-bar bg-success"
          role="progressbar"
          aria-valuemin="0"
          aria-valuemax="100"
          aria-valuenow={percentage}
          style={{width: `${percentage}%`}}
        />
      </div>
      <div className="float-left">{Math.round(percentage)}%</div>
      {finishLabel && <div className="float-right">{finishLabel}</div>}
    </>
  );
}
