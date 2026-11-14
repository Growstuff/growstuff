import React from 'react';

// A crop's icon and name, with the planting's variety in brackets if it has one, linking to a planting. Matches plantings/_tiny.
export default function CropChip({url, crop, variety, defaultIconUrl, highlighted}) {
  const name = variety ? `${crop.name} (${variety})` : crop.name;
  return (
    <a href={url} title={name}>
      <div className={`chip crop-chip${highlighted ? ' planting-just-added' : ''}`}>
        <img className="crop-icon" src={crop.icon_url || defaultIconUrl} alt={crop.name} />
        <span className="crop-chip-name">{name}</span>
      </div>
    </a>
  );
}
