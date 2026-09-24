import React, {useEffect, useRef, useState} from 'react';

import ActionsMenu from './ActionsMenu';
import AddPhotoModal from './AddPhotoModal';
import EditPlantingModal from './EditPlantingModal';
import MarkFinishedModal from './MarkFinishedModal';
import RecordHarvestModal from './RecordHarvestModal';
import SaveSeedsModal from './SaveSeedsModal';

// The menu items we open a dialog for. Anything else — delete, and whatever is
// added later — keeps its link, its data-method and its data-confirm.
const DIALOGS = ['edit', 'harvest', 'seeds', 'finish', 'photo'];

// Transplanting is a server-rendered Bootstrap dialog, already on the page but
// hidden. Its form posts as it always has, so it needs no JSON endpoint.
function showTransplantDialog() {
  const dialog = document.getElementById('transplant-modal');
  if (dialog && window.bootstrap) window.bootstrap.Modal.getOrCreateInstance(dialog).show();
}

// The quiet "add" on each section heading opens the same dialog as the matching
// menu item. Those links are server-rendered, outside this island, so we listen
// for them on the document; their href stays as the fallback without
// JavaScript. The handler is held in a ref so the listener is attached once
// rather than on every render.
function useSectionTriggers(onTrigger) {
  const latest = useRef(onTrigger);
  latest.current = onTrigger;

  useEffect(() => {
    function onClick(event) {
      const trigger = event.target.closest('[data-planting-dialog]');
      if (!trigger) return;
      event.preventDefault();
      latest.current(trigger.dataset.plantingDialog, trigger.getAttribute('href'));
    }

    document.addEventListener('click', onClick);
    return () => document.removeEventListener('click', onClick);
  }, []);
}

// The one actions menu for a planting's own page: the three-dot button in the
// top right of the hero, and the dialogs its items open.
//
// The items come from the server (label, href, and for non-GET links `method`
// and `confirm`), so permissions and wording stay in one place.
//
// Saving reloads the page, because the sections below (facts, harvests, seeds,
// photos) are server-rendered and there is no JSON for them yet. The member
// stays on the planting either way, which is the point; re-rendering only the
// affected section is tracked separately.
export default function PlantingActions({
  planting, actions,
  harvest_icon_url: harvestIconUrl, seed_icon_url: seedIconUrl,
  photo_icon_url: photoIconUrl, finish_icon_url: finishIconUrl
}) {
  // {kind, href}: which dialog is open, and the link it was opened from, which
  // the add-photo dialog needs.
  const [dialog, setDialog] = useState(null);

  const open = (kind, href) => setDialog({kind, href});
  const close = () => setDialog(null);

  // Close the dialog, then reload on the next tick. Reloading straight from the
  // save callback tears the page down while the dialog is still finishing its
  // own update, which leaves the browser wedged mid-navigation.
  const saved = () => {
    setDialog(null);
    setTimeout(() => window.location.reload(), 0);
  };

  useSectionTriggers(open);

  // After the hooks: React counts them, and an early return above would change
  // the count between renders.
  if (!actions || actions.length === 0) return null;

  function choose(action, event) {
    if (action.key === 'transplant') {
      event.preventDefault();
      showTransplantDialog();
    } else if (DIALOGS.includes(action.key)) {
      event.preventDefault();
      open(action.key, action.href);
    }
  }

  const kind = dialog && dialog.kind;

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
      {kind === 'edit' && (
        <EditPlantingModal planting={planting} onClose={close} onSaved={saved} />
      )}
      {kind === 'harvest' && (
        <RecordHarvestModal planting={planting} iconUrl={harvestIconUrl} onClose={close} onSaved={saved} />
      )}
      {kind === 'seeds' && (
        <SaveSeedsModal planting={planting} iconUrl={seedIconUrl} onClose={close} onSaved={saved} />
      )}
      {kind === 'finish' && (
        <MarkFinishedModal planting={planting} iconUrl={finishIconUrl} onClose={close} onSaved={saved} />
      )}
      {kind === 'photo' && (
        <AddPhotoModal
          label={`${planting.crop.name} planting`}
          newUrl={dialog.href}
          iconUrl={photoIconUrl}
          onClose={close}
          onAdded={saved}
        />
      )}
    </>
  );
}
