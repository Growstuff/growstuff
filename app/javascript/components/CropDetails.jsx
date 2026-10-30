import React, {useEffect, useState} from 'react';

import {getJson} from '../api';

function facts(info) {
  const rows = [
    ['Grows', info.perennial ? 'Perennial, comes back each year' : 'Annual'],
    ['Sun', info.sun],
    ['Sow', info.sowing_method],
    ['Days to first harvest', info.days_to_harvest],
    ['Row spacing', info.row_spacing_formatted || (info.row_spacing_cm && `${info.row_spacing_cm} cm`)],
    ['Spread', info.spread_formatted || (info.spread_cm && `${info.spread_cm} cm`)],
    ['Height', info.height_formatted || (info.height_cm && `${info.height_cm} cm`)],
    ['Usually planted from', info.usually_from],
  ];
  return rows.filter(([, value]) => value);
}

// What a chosen crop is, so you can tell it is the right one before sowing: a
// photo, its names, how it grows and what you have done with it before.
export default function CropDetails({slug}) {
  const [info, setInfo] = useState(null);

  useEffect(() => {
    setInfo(null);
    const controller = new AbortController();
    getJson(`/crops/${slug}/sowing_info.json`, {signal: controller.signal})
      .then(({ok, data}) => ok && setInfo(data))
      .catch(() => {});
    return () => controller.abort();
  }, [slug]);

  if (!info) return null;

  const rows = facts(info);
  return (
    <div className="crop-details">
      {info.photo_url && <img className="crop-details-photo" src={info.photo_url} alt={`Photo of ${info.name}`} />}
      <div className="crop-details-text">
        <h3 className="crop-details-name">{info.name}</h3>
        {info.scientific_name && <p className="crop-details-scientific">{info.scientific_name}</p>}
        {info.parent_name && <p className="text-muted mb-1">A kind of {info.parent_name}</p>}
        {info.description && <p>{info.description}</p>}
        {rows.length > 0 && (
          <dl className="crop-details-facts">
            {rows.map(([label, value]) => (
              <React.Fragment key={label}>
                <dt>{label}</dt>
                <dd>{value}</dd>
              </React.Fragment>
            ))}
          </dl>
        )}
        <p className="text-muted mb-0">
          Grown by {info.grown_by} {info.grown_by === 1 ? 'planting' : 'plantings'} on Growstuff.
          {info.your_plantings > 0 && ` You have grown it ${info.your_plantings} ${info.your_plantings === 1 ? 'time' : 'times'}.`}
          {info.your_seeds > 0 && ` You have ${info.your_seeds} ${info.your_seeds === 1 ? 'packet' : 'packets'} of its seeds.`}
          {' '}<a href={info.url} target="_blank" rel="noreferrer">More about {info.name}</a>
        </p>
      </div>
    </div>
  );
}
