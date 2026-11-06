import {useEffect, useRef, useState} from 'react';

import {patchJson, postJson} from '../api';

const DELAY = 1500;

function savedAt() {
  return new Date().toLocaleTimeString([], {hour: 'numeric', minute: '2-digit'});
}

// Saves a post as a draft shortly after its title or body stops changing.
// `autosave` is {createUrl, updateUrl, subjectId}: a post that does not exist
// yet is created on the first save, after which the form is pointed at it so
// that submitting it later updates the draft rather than making another.
// Typing saves nothing until there is a title or some text; a photo is placed
// by saving straight away (`saveNow`), blank or not, as it needs a post to go on.
// Returns {status, saveNow}: the status line to show ('', 'Saving…', '✓ Draft
// saved 10:21 am', or an error), and a function that saves straight away.
export default function useDraftAutosave(markdown, autosave) {
  const [status, setStatus] = useState('');
  const url = useRef(autosave && autosave.updateUrl);
  const first = useRef(true);
  const [subjectTick, setSubjectTick] = useState(0);
  const latest = useRef({});
  latest.current = {markdown, autosave};

  const subjectId = autosave && autosave.subjectId;
  useEffect(() => {
    const input = subjectId && document.getElementById(subjectId);
    if (!input) return undefined;
    const onInput = () => setSubjectTick((n) => n + 1);
    input.addEventListener('input', onInput);
    return () => input.removeEventListener('input', onInput);
  }, [subjectId]);

  // Saves the draft now: updates it, or creates it the first time. Resolves to
  // the draft's address, or null when it could not be saved. Unless `force`,
  // a draft with no title and no text is left unsaved.
  async function save(force = false) {
    const config = latest.current.autosave;
    const input = document.getElementById(config.subjectId);
    const subject = input ? input.value.trim() : '';
    const body = latest.current.markdown;
    if (!force && !subject && !body) return url.current;

    const form = input && input.form;
    const forum = form && form.querySelector('[name="post[forum_id]"]');
    const payload = {post: {subject, body, draft: true}};
    if (forum && forum.value) payload.post.forum_id = forum.value;

    setStatus('Saving…');
    const result = url.current
      ? await patchJson(url.current, payload)
      : await postJson(config.createUrl, payload);
    if (!result.ok) {
      setStatus('Could not save the draft. Your work is still here.');
      return url.current; // null for a draft that was never saved
    }
    if (!url.current && result.data) {
      // By id: a draft's slug follows its title, so it can change.
      url.current = `${config.createUrl}/${result.data.id}`;
      pointFormAt(form, url.current);
    }
    setStatus(`✓ Draft saved ${savedAt()}`);
    return url.current;
  }

  useEffect(() => {
    if (!autosave) return undefined;
    if (first.current) {
      first.current = false;
      return undefined;
    }

    const timer = setTimeout(() => save(false), DELAY);

    return () => clearTimeout(timer);
  }, [markdown, subjectTick]); // eslint-disable-line react-hooks/exhaustive-deps

  return {status, saveNow: () => save(true)};
}

function pointFormAt(form, url) {
  if (!form) return;
  form.action = url;
  let method = form.querySelector('input[name="_method"]');
  if (!method) {
    method = document.createElement('input');
    method.type = 'hidden';
    method.name = '_method';
    form.appendChild(method);
  }
  method.value = 'patch';
}
