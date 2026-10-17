import React from 'react';

import {isPlainClick} from '../events';
import ActionsMenu from './ActionsMenu';
import PlantingChip from './PlantingChip';
import PlantingRow from './PlantingRow';

// One garden, as a row that opens: its picture, name and how it is doing. Opened
// it has a picture, then what is planted, as perennials (just names) and annuals
// (each with its progress). The buttons and menus are for gardens you can change.
export default function GardenCard({garden, defaultOpen, defaultIconUrl, onPlant, highlightedId, highlightKind, onPlantingUpdated, onEditPlanting, onHarvestPlanting, onSaveSeedsPlanting, onAddPhoto, onFinishPlanting, onEditGarden}) {
  const {id, name, url, image_url: imageUrl, layout_url: layoutUrl, owner, actions, plant_url: plantUrl, plantings_count: plantingsCount, harvesting_now: harvestingNow} = garden;
  const {perennials, annuals} = garden;
  const empty = perennials.length === 0 && annuals.length === 0;
  // What each planting's menu items open, for annuals and perennials alike.
  const handlers = {
    edit: onEditPlanting,
    harvest: onHarvestPlanting,
    seeds: onSaveSeedsPlanting,
    finish: onFinishPlanting,
    photo: onAddPhoto && ((planting, action) => onAddPhoto({label: `${planting.crop.name} planting`, href: action.href})),
  };
  function plant(event) {
    if (onPlant && isPlainClick(event)) {
      event.preventDefault();
      onPlant(garden);
    }
  }
  const summary = [
    `${plantingsCount} ${plantingsCount === 1 ? 'planting' : 'plantings'}`,
    harvestingNow > 0 ? `harvesting now: ${harvestingNow}` : null,
  ].filter(Boolean).join(' · ');

  return (
    <details className="garden-card" data-garden-id={id} open={defaultOpen}>
      <summary className="garden-card-summary">
        <a name={`garden-${id}`} className="visually-hidden" aria-hidden="true" tabIndex="-1">{' '}</a>
        <img src={imageUrl} alt="" className="garden-card-thumb" />
        <div className="garden-card-name">
          <b>{name}</b>
          <br />
          <small>{summary}</small>
          {owner && <small className="garden-card-owner"> · owner: {owner.login_name}</small>}
        </div>
        <span className="garden-card-chevron" aria-hidden="true">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M6 9l6 6 6-6" /></svg>
        </span>
      </summary>
      <div className="garden-card-panel">
        <div className="garden-card-actions">
          {layoutUrl && (
            <a href={layoutUrl} className="garden-card-layout-button">
              <i className="fa fa-th-large" aria-hidden="true" /> Layout
              <span className="visually-hidden"> of {name}</span>
            </a>
          )}
          {plantUrl && (
            <a href={plantUrl} className="btn btn-success garden-add-planting" onClick={plant}>
              + Add planting
              <span className="visually-hidden"> to {name}</span>
            </a>
          )}
          {actions.length > 0 && (
            <ActionsMenu
              id={`garden-${id}`}
              actions={actions}
              label={<i className="fas fa-ellipsis-v" aria-hidden="true" />}
              ariaLabel={`Actions for ${name}`}
              className="btn btn-sm btn-link actions-toggle-dots"
              onSelect={(action, event) => {
                if (!isPlainClick(event)) return;
                if (action.key === 'photo' && onAddPhoto) {
                  event.preventDefault();
                  onAddPhoto({label: `${name} garden`, href: action.href});
                } else if (action.key === 'edit' && onEditGarden) {
                  event.preventDefault();
                  onEditGarden(garden);
                }
              }}
            />
          )}
        </div>
        <div className="garden-card-body">
          <img src={imageUrl} alt={`Photo of ${name}`} className="garden-card-image" />
          <div className="garden-card-content">
            {empty ? (
              <p className="garden-card-none">Nothing planted here yet.</p>
            ) : (
              <>
                <section className="garden-card-section">
                  <h3 className="garden-card-heading">Perennials</h3>
                  {perennials.length > 0 ? (
                    <div className="garden-card-chips">
                      {perennials.map((planting) => (
                        <PlantingChip
                          key={planting.id}
                          planting={planting}
                          defaultIconUrl={defaultIconUrl}
                          highlighted={planting.id === highlightedId}
                          handlers={handlers}
                        />
                      ))}
                    </div>
                  ) : (
                    <p className="garden-card-none">None</p>
                  )}
                </section>
                <section className="garden-card-section">
                  <h3 className="garden-card-heading">Annuals</h3>
                  {annuals.length > 0 ? (
                    <div className="planting-rows">
                      {annuals.map((planting) => (
                        <PlantingRow
                          key={planting.id}
                          planting={planting}
                          defaultIconUrl={defaultIconUrl}
                          highlighted={planting.id === highlightedId}
                          highlightKind={highlightKind}
                          onUpdated={onPlantingUpdated}
                          handlers={handlers}
                        />
                      ))}
                    </div>
                  ) : (
                    <p className="garden-card-none">None</p>
                  )}
                </section>
              </>
            )}
          </div>
        </div>
        <a href={url} className="garden-card-open">Open {name} ›</a>
      </div>
    </details>
  );
}
