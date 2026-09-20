import React from 'react';

import ActionsMenu from './ActionsMenu';
import CropChip from './CropChip';
import PlantingRow from './PlantingRow';

// One garden: name and actions menu (top right), image, perennials and the
// annual plantings with their progress. Matches gardens/_card.
export default function GardenCard({garden, defaultIconUrl}) {
  const {id, name, url, image_url: imageUrl, owner, actions, perennials, annuals} = garden;

  return (
    <div className="card mb-3" data-garden-id={id}>
      <div className="card-header d-flex justify-content-between align-items-start">
        <div>
          <h2><a href={url} name={`garden-${id}`}>{name}</a></h2>
          {owner && <div>owner: <a href={owner.url}>{owner.login_name}</a></div>}
        </div>
        <ActionsMenu id={`garden-${id}`} actions={actions} />
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
                    <CropChip key={planting.id} url={planting.url} crop={planting.crop} defaultIconUrl={defaultIconUrl} />
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
                    <PlantingRow planting={planting} defaultIconUrl={defaultIconUrl} />
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
