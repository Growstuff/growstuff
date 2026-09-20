import React from 'react';

import {isPlainClick} from '../events';
import ActionsMenu from './ActionsMenu';
import CropChip from './CropChip';
import PlantingRow from './PlantingRow';

// One garden: its name and actions menu (top right), a picture, then what is
// planted, as perennials (just names) and annuals (each with its progress).
// Matches gardens/_card.
export default function GardenCard({garden, defaultIconUrl, onPlant, highlightedId, onPlantingUpdated, onEditPlanting}) {
  const {id, name, url, image_url: imageUrl, owner, actions, plant_url: plantUrl, perennials, annuals} = garden;
  const empty = perennials.length === 0 && annuals.length === 0;
  function plant(event) {
    if (onPlant && isPlainClick(event)) {
      event.preventDefault();
      onPlant(garden);
    }
  }

  return (
    <div className="card garden-card" data-garden-id={id}>
      <div className="card-header garden-card-header">
        <div>
          <h2 className="garden-card-title"><a href={url} name={`garden-${id}`}>{name}</a></h2>
          {owner && <div className="garden-card-owner">owner: <a href={owner.url}>{owner.login_name}</a></div>}
        </div>
        <div className="garden-card-header-actions">
          {plantUrl && (
            <a href={plantUrl} className="btn btn-success btn-sm garden-add-planting" onClick={plant}>
              <i className="fa fa-plus" aria-hidden="true" /> Add planting
              <span className="visually-hidden"> to {name}</span>
            </a>
          )}
          <ActionsMenu
            id={`garden-${id}`}
            actions={actions}
            label={<i className="fa fa-ellipsis-v" aria-hidden="true" />}
            ariaLabel={`Actions for ${name}`}
            className="btn btn-sm btn-link actions-toggle-dots"
          />
        </div>
      </div>
      <div className="card-body garden-card-body">
        <img src={imageUrl} alt={name} className="garden-card-image" />
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
                      <CropChip
                        key={planting.id}
                        url={planting.url}
                        crop={planting.crop}
                        defaultIconUrl={defaultIconUrl}
                        highlighted={planting.id === highlightedId}
                        onUpdated={onPlantingUpdated}
                        onEdit={onEditPlanting}
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
                        onUpdated={onPlantingUpdated}
                        onEdit={onEditPlanting}
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
    </div>
  );
}
