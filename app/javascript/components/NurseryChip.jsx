import React, {useState} from 'react';

import AddPhotoModal from './AddPhotoModal';
import PlantingChip from './PlantingChip';

// One batch in the nursery: the same chip, with its menu, as a planting on a
// garden card, then how many there are. "Add photo" opens its dialog over the
// page, as on a card. In edit mode `pick` adds a tick for planting it out; the
// tick is a plain checkbox in the nursery's form.
export default function NurseryChip({planting, default_icon_url: defaultIconUrl, photo_icon_url: photoIconUrl, detail, pick}) {
  const [addingPhoto, setAddingPhoto] = useState(null); // {label, href}
  const handlers = {photo: (chosen, action) => setAddingPhoto({label: `${chosen.crop.name} planting`, href: action.href})};

  return (
    <>
      {pick && (
        <input
          type="checkbox"
          name="batch_ids[]"
          value={planting.id}
          id={`pick_${planting.id}`}
          className="nursery-pick-box"
          aria-label={`Plant out ${planting.crop.name}`}
        />
      )}
      <PlantingChip planting={planting} defaultIconUrl={defaultIconUrl} handlers={handlers} />
      {detail && <small className="nursery-chip-detail">{detail}</small>}
      {addingPhoto && (
        <AddPhotoModal
          label={addingPhoto.label}
          newUrl={addingPhoto.href}
          iconUrl={photoIconUrl}
          onClose={() => setAddingPhoto(null)}
          onAdded={() => window.location.reload()} // the day's photos change
        />
      )}
    </>
  );
}
