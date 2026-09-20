import React, {useEffect} from 'react';

import GardenCard from './GardenCard';

// The list of garden cards on the gardens index. Props come from
// GardensHelper#garden_cards_props.
export default function GardenCards({gardens, default_icon_url: defaultIconUrl}) {
  // The "jump to" links point at #garden-<id>, but the cards only exist once
  // React has mounted, after the browser has already tried to scroll.
  useEffect(() => {
    if (!window.location.hash) return;
    const target = document.getElementsByName(window.location.hash.slice(1))[0];
    if (target) target.scrollIntoView();
  }, []);

  return (
    <>
      {gardens.map((garden) => (
        <GardenCard key={garden.id} garden={garden} defaultIconUrl={defaultIconUrl} />
      ))}
    </>
  );
}
