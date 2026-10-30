import React, {useEffect, useRef, useState} from 'react';

import {getJson} from '../api';
import PlantingFlow from './PlantingFlow';

// The record harvest and save seeds dialogs for every server-rendered link to
// the full form. Nothing of its own is drawn: it listens for clicks on any
// [data-record-dialog="harvest"] or [data-record-dialog="seeds"] link on the
// page and opens the same dialog the home page does. A link for a particular
// crop says which in data-crop-id and data-crop-name. The layout mounts it once.
//
// The member's plantings come from plantingsUrl when first needed. The link's
// own href stays the fallback without JavaScript, and when the plantings cannot
// be loaded.
export default function RecordDialog({plantings_url: plantingsUrl}) {
  const [opened, setOpened] = useState(null); // {action, crop}, or null when closed
  const [plantings, setPlantings] = useState(null);
  const open = useRef(null);
  open.current = async (trigger) => {
    const action = trigger.dataset.recordDialog;
    const crop = trigger.dataset.cropId ? {id: Number(trigger.dataset.cropId), name: trigger.dataset.cropName} : null;
    if (!plantings) {
      try {
        const {ok, data} = await getJson(plantingsUrl);
        if (!ok) throw new Error('load failed');
        setPlantings(data);
      } catch (error) {
        window.location.href = trigger.getAttribute('href');
        return;
      }
    }
    setOpened({action, crop});
  };

  useEffect(() => {
    function onClick(event) {
      const trigger = event.target.closest('[data-record-dialog]');
      if (!trigger) return;
      event.preventDefault();
      open.current(trigger);
    }

    document.addEventListener('click', onClick);
    return () => document.removeEventListener('click', onClick);
  }, []);

  if (!opened || !plantings) return null;

  return <PlantingFlow action={opened.action} crop={opened.crop} plantings={plantings} onClose={() => setOpened(null)} />;
}
