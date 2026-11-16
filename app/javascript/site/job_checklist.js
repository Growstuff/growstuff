// A planting's jobs as a checklist: ticking a job saves it and draws just that
// line again, without reloading the page. If saving goes wrong the form is sent
// the usual way, which reloads the page and shows how things stand.

import {csrfToken} from '../api';

document.addEventListener('submit', function (event) {
  const tick = event.target.closest && event.target.closest('.job-checklist-tick');
  if (!tick) return;

  event.preventDefault();
  const item = tick.closest('.job-checklist-item');
  const body = new FormData(tick);
  body.append('checklist', '1');
  item.setAttribute('aria-busy', 'true');

  fetch(tick.action, {
    method: 'POST',
    body: body,
    headers: {'X-CSRF-Token': csrfToken(), Accept: 'text/html'},
    credentials: 'same-origin',
  })
    .then(function (response) {
      if (!response.ok) throw new Error(response.status);
      return response.text();
    })
    .then(function (html) {
      const template = document.createElement('template');
      template.innerHTML = html.trim();
      const fresh = template.content.firstElementChild;
      item.replaceWith(fresh);
      const box = fresh.querySelector('.job-box');
      if (box) box.focus();
    })
    .catch(function () {
      tick.submit();
    });
});
