import React, {useEffect, useRef, useState} from 'react';

import EditPlantingModal from './EditPlantingModal';
import GardenCard from './GardenCard';
import PlantSomethingModal from './PlantSomethingModal';

const plantingIds = (garden) => [...garden.perennials, ...garden.annuals].map((planting) => planting.id);

// The list of garden cards on the gardens index. Props come from
// GardensHelper#garden_cards_props. It owns the cards' state so that saving a
// planting from the "Add planting" dialog can swap in the garden's
// updated card, and the new planting appears without a page reload.
export default function GardenCards({gardens: initialGardens, default_icon_url: defaultIconUrl, spade_icon_url: spadeIconUrl}) {
  const [gardens, setGardens] = useState(initialGardens);
  const [plantingIn, setPlantingIn] = useState(null); // the garden the dialog is open for
  const [editing, setEditing] = useState(null); // the planting the edit dialog is open for
  const [notice, setNotice] = useState(null);
  const [highlightedId, setHighlightedId] = useState(null);
  const highlightTimer = useRef(null);

  // The "jump to" links point at #garden-<id>, but the cards only exist once
  // React has mounted, after the browser has already tried to scroll.
  useEffect(() => {
    if (!window.location.hash) return;
    const target = document.getElementsByName(window.location.hash.slice(1))[0];
    if (target) target.scrollIntoView();
  }, []);

  useEffect(() => () => clearTimeout(highlightTimer.current), []);

  // The response leaves out the owner (the page already has it); keep ours.
  function replaceCard(updatedCard) {
    setGardens((current) => current.map((garden) => (garden.id === updatedCard.id ? {...updatedCard, owner: garden.owner} : garden)));
  }

  function created(updatedCard, crop) {
    const before = gardens.find((garden) => garden.id === updatedCard.id);
    const known = new Set(plantingIds(before));
    const added = plantingIds(updatedCard).find((id) => !known.has(id));

    replaceCard(updatedCard);
    setPlantingIn(null);
    setNotice(`Planted ${crop ? crop.name : 'something'} in ${updatedCard.name}.`);
    setHighlightedId(added);
    clearTimeout(highlightTimer.current);
    highlightTimer.current = setTimeout(() => setHighlightedId(null), 4000);
  }

  function edited(updatedCard, planting) {
    replaceCard(updatedCard);
    setEditing(null);
    setNotice(`Saved changes to ${planting.crop.name}.`);
  }

  return (
    <>
      {notice && (
        <div className="alert alert-success alert-dismissible" role="status">
          <i className="fa fa-check-circle" aria-hidden="true" /> {notice}
          <button type="button" className="btn-close" aria-label="Dismiss" onClick={() => setNotice(null)} />
        </div>
      )}
      {gardens.map((garden) => (
        <GardenCard
          key={garden.id}
          garden={garden}
          defaultIconUrl={defaultIconUrl}
          onPlant={setPlantingIn}
          highlightedId={highlightedId}
          onPlantingUpdated={replaceCard}
          onEditPlanting={setEditing}
        />
      ))}
      {editing && (
        <EditPlantingModal
          planting={editing}
          onClose={() => setEditing(null)}
          onSaved={(updatedCard) => edited(updatedCard, editing)}
        />
      )}
      {plantingIn && (
        <PlantSomethingModal
          garden={plantingIn}
          iconUrl={spadeIconUrl}
          onClose={() => setPlantingIn(null)}
          onCreated={created}
        />
      )}
    </>
  );
}
