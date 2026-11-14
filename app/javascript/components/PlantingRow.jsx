import React from 'react';

import PlantedDate from './PlantedDate';
import PlantingChip from './PlantingChip';
import PlantingTimeline from './PlantingTimeline';

// One annual planting as a row of two aligned columns: the crop, which is also
// the planting's menu (and when it was planted), and how it is getting on
// (badges, then the timeline of its events, or a note when there is nothing to predict from).
// `handlers` is what the menu's items open (see selectPlantingAction).
export default function PlantingRow({planting, defaultIconUrl, highlighted, highlightKind = 'added', onUpdated, handlers}) {
  const {badges} = planting;

  return (
    <div className={`planting-row${highlighted ? ` planting-just-${highlightKind}` : ''}`}>
      {planting.thumb_url ? (
        <img className="planting-row-thumb" src={planting.thumb_url} alt={`Photo of ${planting.crop.name}`} />
      ) : (
        <span className="planting-row-thumb planting-row-thumb-none" />
      )}
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
        {planting.timeline ? (
          <PlantingTimeline timeline={planting.timeline} compact />
        ) : (
          planting.progress_note && <small className="planting-row-note">{planting.progress_note}</small>
        )}
      </div>
    </div>
  );
}
