import React from 'react';

// A crop's icon and name, linking to a planting. Matches plantings/_tiny. `label` is what it says when that is more
// than the crop's name, as for a planting of a variety: "tomato (Brandywine)".
export default function CropChip({url, crop, label = crop.name, defaultIconUrl, highlighted}) {
  return (
    <a href={url} title={label}>
      <div className={`chip crop-chip${highlighted ? ' planting-just-added' : ''}`}>
        <img className="crop-icon" src={crop.icon_url || defaultIconUrl} alt={crop.name} />
        <span className="crop-chip-name">{label}</span>
      </div>
    </a>
  );
}
