import React from 'react';

import ActionsMenu from './ActionsMenu';
import CropChip from './CropChip';
import PlantingRow from './PlantingRow';

// One garden: name and actions menu (top right), image, perennials and the
// annual plantings with their progress. Matches gardens/_card.
// A plain left click, as opposed to ctrl/cmd/shift/middle click, which should still open the link normally.
function isPlainClick(event) {
  return event.button === 0 && !(event.metaKey || event.ctrlKey || event.shiftKey || event.altKey);
}

export default function GardenCard({garden, defaultIconUrl, onPlant, highlightedId}) {
  const {id, name, url, image_url: imageUrl, owner, actions, perennials, annuals} = garden;

  return (
    <div className="card mb-3" data-garden-id={id}>
      <div className="card-header d-flex justify-content-between align-items-start">
        <div>
          <h2><a href={url} name={`garden-${id}`}>{name}</a></h2>
          {owner && <div>owner: <a href={owner.url}>{owner.login_name}</a></div>}
        </div>
        <ActionsMenu
          id={`garden-${id}`}
          actions={actions}
          onSelect={(action, event) => {
            if (action.key === 'plant' && onPlant && isPlainClick(event)) {
              event.preventDefault();
              onPlant(garden);
            }
          }}
        />
      </div>
      <div className="card-body">
        <div className="row">
          <div className="col-md-3">
            <img src={imageUrl} alt={name} className="img-card" />
          </div>
          <div className="col-md-9">
            <section>
              {perennials.length > 0 ? (
                <>
                  <strong>Perennials:</strong>
                  {perennials.map((planting) => (
                    <CropChip
                      key={planting.id}
                      url={planting.url}
                      crop={planting.crop}
                      defaultIconUrl={defaultIconUrl}
                      highlighted={planting.id === highlightedId}
                    />
                  ))}
                </>
              ) : (
                <p>No perennial plantings</p>
              )}
            </section>
            <hr />
            <section>
              {annuals.length > 0 ? (
                annuals.map((planting, index) => (
                  <React.Fragment key={planting.id}>
                    {index > 0 && <hr />}
                    <PlantingRow
                      planting={planting}
                      defaultIconUrl={defaultIconUrl}
                      highlighted={planting.id === highlightedId}
                    />
                  </React.Fragment>
                ))
              ) : (
                <p>No annual plantings</p>
              )}
            </section>
          </div>
        </div>
      </div>
    </div>
  );
}
