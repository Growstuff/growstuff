import React, {useState} from 'react';

import {refreshNursery, showSaved} from '../nurseryPanel';
import AddPhotoModal from './AddPhotoModal';
import EditPlantingModal from './EditPlantingModal';
import PlantingChip from './PlantingChip';
import TransplantModal from './TransplantModal';

// One batch in the nursery: the same chip, with its menu, as a planting on a
// garden card, then how many there are, all in one pill. "Add photo" and
// "Edit" and "Transplant" open their dialogs over the page, as on a card. What
// is saved shows without leaving the page: the nursery is fetched afresh.
export default function NurseryChip({planting, default_icon_url: defaultIconUrl, photo_icon_url: photoIconUrl, gardens, detail}) {
  const [addingPhoto, setAddingPhoto] = useState(null); // {label, href}
  const [editing, setEditing] = useState(false);
  const [transplanting, setTransplanting] = useState(false);
  const handlers = {
    photo: (chosen, action) => setAddingPhoto({label: `${chosen.crop.name} planting`, href: action.href}),
    edit: () => setEditing(true),
    transplant: () => setTransplanting(true),
  };

  return (
    <div className="nursery-batch">
      <PlantingChip planting={planting} defaultIconUrl={defaultIconUrl} handlers={handlers} />
      {detail && <small className="nursery-chip-detail">{detail}</small>}
      {editing && (
        <EditPlantingModal planting={planting} onClose={() => setEditing(false)} onSaved={refreshNursery} />
      )}
      {transplanting && (
        <TransplantModal
          planting={planting}
          gardens={gardens}
          onClose={() => setTransplanting(false)}
          onDone={showSaved}
        />
      )}
      {addingPhoto && (
        <AddPhotoModal
          label={addingPhoto.label}
          newUrl={addingPhoto.href}
          iconUrl={photoIconUrl}
          onClose={() => setAddingPhoto(null)}
          onAdded={refreshNursery} // the day's photos change
        />
      )}
    </div>
  );
}
