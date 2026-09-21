import React, {useEffect, useRef, useState} from 'react';

import EditPlantingModal from './EditPlantingModal';
import GardenCard from './GardenCard';
import PlantSomethingModal from './PlantSomethingModal';
import RecordHarvestModal from './RecordHarvestModal';
import SaveSeedsModal from './SaveSeedsModal';

const plantingIds = (garden) => [...garden.perennials, ...garden.annuals].map((planting) => planting.id);

// The list of garden cards on the gardens index. Props come from
// GardensHelper#garden_cards_props. It owns the cards' state so that saving a
// planting from the "Add planting" dialog can swap in the garden's
// updated card, and the new planting appears without a page reload.
export default function GardenCards({gardens: initialGardens, default_icon_url: defaultIconUrl, spade_icon_url: spadeIconUrl, harvest_icon_url: harvestIconUrl, seed_icon_url: seedIconUrl}) {
  const [gardens, setGardens] = useState(initialGardens);
  const [plantingIn, setPlantingIn] = useState(null); // the garden the dialog is open for
  const [editing, setEditing] = useState(null); // the planting the edit dialog is open for
  const [harvesting, setHarvesting] = useState(null); // the planting the harvest dialog is open for
  const [savingSeeds, setSavingSeeds] = useState(null); // the planting the save seeds dialog is open for
  const [notice, setNotice] = useState(null);
  const [highlight, setHighlight] = useState(null); // {id, kind}: the planting just added or harvested
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
    flash(added, 'added');
  }

  // Picks out a planting for a few seconds, so you can see which one changed.
  function flash(id, kind) {
    setHighlight({id, kind});
    clearTimeout(highlightTimer.current);
    highlightTimer.current = setTimeout(() => setHighlight(null), 5000);
  }

  function edited(updatedCard, planting) {
    replaceCard(updatedCard);
    setEditing(null);
    setNotice(`Saved changes to ${planting.crop.name}.`);
  }

  function harvested(updatedCard, planting) {
    replaceCard(updatedCard);
    setHarvesting(null);
    setNotice(`Recorded a harvest of ${planting.crop.name} in ${updatedCard.name}.`);
    flash(planting.id, 'harvested');
  }

  function seedsSaved(seed, planting) {
    setSavingSeeds(null);
    setNotice(<>Saved {planting.crop.name} seeds to your stash. <a href={seed.url}>See them</a>.</>);
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
          highlightedId={highlight && highlight.id}
          highlightKind={highlight && highlight.kind}
          onPlantingUpdated={replaceCard}
          onEditPlanting={setEditing}
          onHarvestPlanting={setHarvesting}
          onSaveSeedsPlanting={setSavingSeeds}
        />
      ))}
      {editing && (
        <EditPlantingModal
          planting={editing}
          onClose={() => setEditing(null)}
          onSaved={(updatedCard) => edited(updatedCard, editing)}
        />
      )}
      {harvesting && (
        <RecordHarvestModal
          planting={harvesting}
          iconUrl={harvestIconUrl}
          onClose={() => setHarvesting(null)}
          onSaved={(updatedCard) => harvested(updatedCard, harvesting)}
        />
      )}
      {savingSeeds && (
        <SaveSeedsModal
          planting={savingSeeds}
          iconUrl={seedIconUrl}
          onClose={() => setSavingSeeds(null)}
          onSaved={(seed) => seedsSaved(seed, savingSeeds)}
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
