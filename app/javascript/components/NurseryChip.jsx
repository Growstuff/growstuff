import React, {useState} from 'react';

import AddPhotoModal from './AddPhotoModal';
import PlantingChip from './PlantingChip';
import TransplantModal from './TransplantModal';

// One batch in the nursery: the same chip, with its menu, as a planting on a
// garden card, then how many there are, all in one pill. "Add photo" and
// "Transplant" open their dialogs over the page, as on a card.
export default function NurseryChip({planting, default_icon_url: defaultIconUrl, photo_icon_url: photoIconUrl, gardens, detail}) {
  const [addingPhoto, setAddingPhoto] = useState(null); // {label, href}
  const [transplanting, setTransplanting] = useState(false);
  const handlers = {
    photo: (chosen, action) => setAddingPhoto({label: `${chosen.crop.name} planting`, href: action.href}),
    transplant: () => setTransplanting(true),
  };

  return (
    <div className="nursery-batch">
      <PlantingChip planting={planting} defaultIconUrl={defaultIconUrl} handlers={handlers} />
      {detail && <small className="nursery-chip-detail">{detail}</small>}
      {transplanting && (
        <TransplantModal
          planting={planting}
          gardens={gardens}
          onClose={() => setTransplanting(false)}
          onDone={() => window.location.reload()}
        />
      )}
      {addingPhoto && (
        <AddPhotoModal
          label={addingPhoto.label}
          newUrl={addingPhoto.href}
          iconUrl={photoIconUrl}
          onClose={() => setAddingPhoto(null)}
          onAdded={() => window.location.reload()} // the day's photos change
        />
      )}
    </div>
  );
}
