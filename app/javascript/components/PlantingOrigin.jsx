import React, {useEffect, useRef, useState} from 'react';

import OriginDialog from './OriginDialog';
import {patchJson} from '../api';

// The "Grown from" fact is server-rendered with the rest of the facts, so its change link is outside this island; we listen
// for it on the document, as PlantingActions does for its section links.
function useDialogTriggers(onTrigger) {
  const latest = useRef(onTrigger);
  latest.current = onTrigger;

  useEffect(() => {
    function onClick(event) {
      if (!event.target.closest('[data-origin-dialog]')) return;
      event.preventDefault();
      latest.current();
    }

    document.addEventListener('click', onClick);
    return () => document.removeEventListener('click', onClick);
  }, []);
}

// The dialog that asks how a planting was started, opened from the "Grown from" fact. An answer goes to the server, then the page
// loads again, because the facts and the title may change with it (a packet of a variety makes this a planting of the variety).
export default function PlantingOrigin({
  url, crop, crop_id: cropId, kinds, seeds, current_seed: currentSeed, seed_sources: seedSources, seedling_sources: seedlingSources, labels,
}) {
  const [open, setOpen] = useState(false);

  useDialogTriggers(() => setOpen(true));

  async function save(body) {
    const {ok, data} = await patchJson(url, body);
    if (ok) {
      setOpen(false);
      setTimeout(() => window.location.assign(data.url), 0);
    }
    return ok;
  }

  if (!open) return null;

  return (
    <OriginDialog
      crop={crop} cropId={cropId} kinds={kinds} seeds={seeds} currentSeed={currentSeed} seedSources={seedSources}
      seedlingSources={seedlingSources} labels={labels} onSave={save} onClose={() => setOpen(false)}
    />
  );
}
