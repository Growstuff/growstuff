import React, {useEffect, useState} from 'react';

import {getJson} from '../api';

// A chosen seed packet, drawn as a packet: the crimped top, a window with its
// photo (the packet's own, else the crop's) and the crop's name.
export default function SeedPacket({packet}) {
  const [cropPhoto, setCropPhoto] = useState(null);
  const photo = packet.photo_url || cropPhoto;

  useEffect(() => {
    setCropPhoto(null);
    if (packet.photo_url) return undefined;
    const controller = new AbortController();
    getJson(`/crops/${packet.crop_slug}/sowing_info.json`, {signal: controller.signal})
      .then(({ok, data}) => ok && setCropPhoto(data.photo_url))
      .catch(() => {});
    return () => controller.abort();
  }, [packet.id, packet.photo_url, packet.crop_slug]);

  return (
    <figure className="seed-packet-picture">
      <div className="seed-packet-crimp" aria-hidden="true" />
      <div className="seed-packet-front">
        <div className="seed-packet-window">
          {photo && <img src={photo} alt={`Photo of ${packet.name}`} />}
        </div>
        <figcaption className="seed-packet-label">{packet.name}</figcaption>
      </div>
    </figure>
  );
}
