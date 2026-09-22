import React, {useState} from 'react';

import ActionsMenu from './ActionsMenu';
import AddPhotoModal from './AddPhotoModal';
import EditPlantingModal from './EditPlantingModal';
import MarkFinishedModal from './MarkFinishedModal';
import RecordHarvestModal from './RecordHarvestModal';
import SaveSeedsModal from './SaveSeedsModal';

// The one actions menu for a planting's own page: the three-dot button in the
// top right of the hero, and the dialogs its items open.
//
// The menu items come from the server (label, href, and for non-GET links
// `method` and `confirm`), so permissions and wording stay in one place. Items
// we have a dialog for are taken over here; the rest follow their link, which
// is also what a ctrl-click or a member without JavaScript gets.
//
// Saving reloads the page, because the sections below (facts, harvests, seeds,
// photos) are server-rendered and there is no JSON for them yet. The member
// stays on the planting either way, which is the point; re-rendering only the
// affected section is tracked separately.
export default function PlantingActions({
  planting, actions, harvest_icon_url: harvestIconUrl, seed_icon_url: seedIconUrl,
  photo_icon_url: photoIconUrl, finish_icon_url: finishIconUrl
}) {
  const [open, setOpen] = useState(null); // which dialog: 'edit' | 'harvest' | ...
  const [photo, setPhoto] = useState(null); // the add-photo action, for its href

  if (!actions || actions.length === 0) return null;

  function choose(action, event) {
    if (action.key === 'photo') {
      event.preventDefault();
      setPhoto(action);
      setOpen('photo');
    } else if (action.key === 'transplant') {
      // A server-rendered Bootstrap dialog, already on the page but hidden: the
      // form posts as it always has, so this needs no JSON endpoint.
      event.preventDefault();
      const dialog = document.getElementById('transplant-modal');
      if (dialog && window.bootstrap) window.bootstrap.Modal.getOrCreateInstance(dialog).show();
    } else if (['edit', 'harvest', 'seeds', 'finish'].includes(action.key)) {
      event.preventDefault();
      setOpen(action.key);
    }
    // 'delete' and anything else keeps its link, data-method and data-confirm.
  }

  const close = () => setOpen(null);
  const saved = () => window.location.reload();

  return (
    <>
      <ActionsMenu
        id={planting.id}
        actions={actions}
        className="btn planting-actions-toggle"
        ariaLabel="Actions"
        label={<i className="fas fa-ellipsis-v" aria-hidden="true" title="Actions" />}
        onSelect={choose}
      />
      {open === 'edit' && (
        <EditPlantingModal planting={planting} onClose={close} onSaved={saved} />
      )}
      {open === 'harvest' && (
        <RecordHarvestModal planting={planting} iconUrl={harvestIconUrl} onClose={close} onSaved={saved} />
      )}
      {open === 'seeds' && (
        <SaveSeedsModal planting={planting} iconUrl={seedIconUrl} onClose={close} onSaved={saved} />
      )}
      {open === 'finish' && (
        <MarkFinishedModal planting={planting} iconUrl={finishIconUrl} onClose={close} onSaved={saved} />
      )}
      {open === 'photo' && photo && (
        <AddPhotoModal
          label={planting.crop.name}
          newUrl={photo.href}
          iconUrl={photoIconUrl}
          onClose={close}
          onAdded={saved}
        />
      )}
    </>
  );
}
