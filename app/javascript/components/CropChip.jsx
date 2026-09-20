import React from 'react';

// A crop's icon and name, linking to a planting. Matches plantings/_tiny.
export default function CropChip({url, crop, defaultIconUrl, highlighted}) {
  return (
    <a href={url}>
      <div className="chip crop-chip" style={highlighted ? {backgroundColor: '#d4edda'} : undefined}>
        <img className="crop-icon" src={crop.icon_url || defaultIconUrl} alt={crop.name} />
        {crop.name}
      </div>
    </a>
  );
}
