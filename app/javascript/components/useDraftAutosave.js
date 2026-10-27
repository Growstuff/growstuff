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
// Nothing is saved until there is both a title and a body, which a post needs.
// Returns the status line to show: '', 'Saving…', '✓ Draft saved 10:21 am', or
// an error.
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

  useEffect(() => {
    if (!autosave) return undefined;
    if (first.current) {
      first.current = false;
      return undefined;
    }

    const timer = setTimeout(async () => {
      const input = document.getElementById(autosave.subjectId);
      const subject = input ? input.value.trim() : '';
      const body = latest.current.markdown;
      if (!subject || !body) return;

      const form = input.form;
      const forum = form && form.querySelector('[name="post[forum_id]"]');
      const payload = {post: {subject, body, draft: true}};
      if (forum && forum.value) payload.post.forum_id = forum.value;

      setStatus('Saving…');
      const result = url.current
        ? await patchJson(url.current, payload)
        : await postJson(autosave.createUrl, payload);
      if (!result.ok) {
        setStatus('Could not save the draft. Your work is still here.');
        return;
      }
      if (!url.current && result.data) {
        url.current = `${autosave.createUrl}/${result.data.slug || result.data.id}`;
        pointFormAt(form, url.current);
      }
      setStatus(`✓ Draft saved ${savedAt()}`);
    }, DELAY);

    return () => clearTimeout(timer);
  }, [markdown, subjectTick]); // eslint-disable-line react-hooks/exhaustive-deps

  return status;
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
