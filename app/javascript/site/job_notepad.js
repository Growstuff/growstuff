// The jobs notepad: adding a job, moving it between days, and linking it to a
// crop, planting or seeds, all without reloading the page. The server sends back
// the notepad's groups after each change. If adding a job goes wrong, the job
// stays in the box and a message says so: it is not sent again, since the first
// may have worked and a second would add the job twice. A move or a tick that
// goes wrong reloads the page, which shows how things stand.

import {celebrate, doneText, hide} from './job_celebration';
import {nextStreak, undoStreak} from './job_streak';

document.addEventListener('DOMContentLoaded', function () {
  const form = document.querySelector('.notepad-add');
  const groups = document.getElementById('notepad-groups');
  if (!form || !groups) return;

  const input = form.querySelector('input[type="text"]');
  const failure = document.getElementById('notepad-add-failed');
  const token = document.querySelector('meta[name="csrf-token"]');
  const kinds = JSON.parse(form.dataset.kinds);
  const words = JSON.parse(groups.dataset.celebrations);
  const reload = function () { window.location.reload(); };

  // The line beside the snail says how many jobs are done this week.
  const caption = document.getElementById('notepad-snail-caption');
  const showDone = function (done) {
    if (caption) caption.textContent = done > 0 ? words.slow + ' ' + doneText(words, done) : words.slow;
  };

  // The tick box or menu button with focus in the list, as the job it belongs to
  // and which control it is, so its replacement can be focused when the list is
  // drawn again.
  const focusedControl = function () {
    const el = document.activeElement;
    const row = el && groups.contains(el) ? el.closest('.notepad-job') : null;
    const selector = row && ['.notepad-box', '.record-actions-toggle'].find(function (candidate) { return el.matches(candidate); });
    return selector ? {id: row.dataset.id, selector: selector} : null;
  };

  // Sends a change to the server and shows the groups it sends back. Resolves
  // with how many jobs are done this week.
  const transmit = function (url, body) {
    return fetch(url, {
      method: 'POST',
      body: body,
      headers: {
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': token ? token.content : '',
      },
      credentials: 'same-origin',
    })
      .then(function (response) {
        if (!response.ok) throw new Error(response.status);
        const done = response.headers.get('X-Jobs-Done-This-Week');
        return response.text().then(function (html) {
          const focused = focusedControl();
          groups.innerHTML = html;
          showDone(Number(done));
          const again = focused && groups.querySelector('.notepad-job[data-id="' + focused.id + '"] ' + focused.selector);
          if (again) again.focus();
          return Number(done);
        });
      });
  };

  // Changes are sent one at a time, in the order they were made. Sent together,
  // an older answer could arrive last and put an older list, and count, on show.
  let queue = Promise.resolve();
  const send = function (url, body) {
    const sent = queue.then(function () { return transmit(url, body); });
    queue = sent.catch(function () {});
    return sent;
  };

  // ---- Crossing a job off, or putting it back

  let streak = 0;
  let lastAt = null;

  const setFinished = function (url, finished) {
    const body = new FormData();
    body.append('_method', 'patch');
    body.append('job[finished]', finished ? '1' : '0');
    return send(url, body);
  };

  groups.addEventListener('submit', function (event) {
    const tick = event.target.closest('.notepad-tick');
    if (!tick) return;
    event.preventDefault();

    const finishing = tick.querySelector('input[name="job[finished]"]').value === '1';
    const name = tick.closest('.notepad-job').querySelector('.notepad-name').textContent;
    const box = tick.getBoundingClientRect();
    const url = tick.action;

    send(url, new FormData(tick))
      .then(function (done) {
        if (!finishing) {
          streak = undoStreak(streak);
          return hide();
        }

        streak = nextStreak(streak, lastAt, Date.now());
        lastAt = Date.now();
        celebrate({
          words: words,
          name: name,
          done: done,
          streak: streak,
          origin: {x: box.left + box.width / 2, y: box.top + box.height / 2},
          onUndo: function () {
            streak = undoStreak(streak);
            setFinished(url, false).catch(reload);
          },
        });
      })
      .catch(function () {
        tick.submit();
      });
  });

  // ---- Adding a job

  const link = document.getElementById('notepad-link');
  const typeField = document.getElementById('notepad-jobbable-type');
  const idField = document.getElementById('notepad-jobbable-id');
  let adding = false;

  const clearLink = function () {
    typeField.value = '';
    idField.value = '';
    link.hidden = true;
  };

  form.addEventListener('submit', function (event) {
    event.preventDefault();
    if (adding || !input.value.trim()) return;
    adding = true;
    failure.hidden = true;
    const submitted = input.value;

    send(form.action, new FormData(form))
      .then(function () {
        // Typing the next job while this one was sent is not to be lost.
        if (input.value === submitted) {
          input.value = '';
          clearLink();
        }
        input.focus();
        adding = false;
      })
      .catch(function () {
        failure.hidden = false;
        adding = false;
      });
  });

  // ---- Moving a job to a day

  // Each group says which day a job dropped in it gets, in data-drop ("none" for
  // no day). The row menu does the same for keyboard and touch.
  let dragged = null;

  const dropTarget = function (event) {
    const group = event.target.closest('.notepad-group');
    return group && group.dataset.drop ? group : null;
  };

  const clearDropTargets = function () {
    groups.querySelectorAll('.drop-over').forEach(function (el) { el.classList.remove('drop-over'); });
  };

  groups.addEventListener('dragstart', function (event) {
    const row = event.target.closest('.notepad-job');
    if (!row) return;
    dragged = row;
    row.classList.add('dragging');
    event.dataTransfer.effectAllowed = 'move';
    event.dataTransfer.setData('text/plain', row.dataset.url);
  });

  groups.addEventListener('dragend', function () {
    if (dragged) dragged.classList.remove('dragging');
    dragged = null;
    clearDropTargets();
  });

  groups.addEventListener('dragover', function (event) {
    const group = dropTarget(event);
    if (!dragged || !group) return;
    event.preventDefault();
    clearDropTargets();
    group.classList.add('drop-over');
  });

  groups.addEventListener('drop', function (event) {
    const group = dropTarget(event);
    if (!dragged || !group) return;
    event.preventDefault();

    const body = new FormData();
    body.append('_method', 'patch');
    body.append('job[due_date]', group.dataset.drop === 'none' ? '' : group.dataset.drop);

    send(dragged.dataset.url, body).catch(reload);
  });

  // ---- Linking a job: typing @ and a crop name offers your plantings and seeds
  // of it, then the crop. Picking one swaps the @ text for the crop's name.

  const list = document.getElementById('notepad-suggestions');
  let items = [];
  let active = -1;
  let timer = null;
  let latest = 0;

  const close = function () {
    items = [];
    active = -1;
    list.hidden = true;
    list.innerHTML = '';
    input.setAttribute('aria-expanded', 'false');
    input.removeAttribute('aria-activedescendant');
  };

  const setActive = function (index) {
    active = index;
    Array.prototype.forEach.call(list.children, function (option, i) {
      option.setAttribute('aria-selected', i === index ? 'true' : 'false');
      option.classList.toggle('active', i === index);
    });
    if (index >= 0) input.setAttribute('aria-activedescendant', list.children[index].id);
  };

  // The @ and the letters after it, up to the cursor.
  const mention = function () {
    const before = input.value.slice(0, input.selectionStart);
    const match = /(^|\s)@([^@]*)$/.exec(before);
    if (!match) return null;
    return { start: match.index + match[1].length, query: match[2].trim() };
  };

  const pick = function (item) {
    const found = mention();
    if (found) {
      const rest = input.value.slice(input.selectionStart).replace(/^\s+/, '');
      const text = input.value.slice(0, found.start) + item.crop_name + ' ';
      input.value = text + rest;
      input.setSelectionRange(text.length, text.length);
    }
    typeField.value = item.jobbable_type;
    idField.value = item.jobbable_id;
    link.querySelector('.notepad-link-text').textContent = kinds[item.kind] + ': ' + item.label;
    link.hidden = false;
    close();
    input.focus();
  };

  const render = function () {
    list.innerHTML = '';
    items.forEach(function (item, i) {
      const option = document.createElement('li');
      option.id = 'notepad-suggestion-' + i;
      option.setAttribute('role', 'option');
      option.className = 'notepad-suggestion';
      const icon = document.createElement('img');
      icon.className = 'notepad-suggestion-icon';
      icon.src = item.icon_url;
      icon.alt = '';
      option.appendChild(icon);
      [['kind', 'span', kinds[item.kind]], ['', 'span', item.label], ['', 'small', item.detail]].forEach(function (part) {
        if (!part[2]) return;
        const el = document.createElement(part[1]);
        el.className = part[0];
        el.textContent = part[2];
        option.appendChild(el);
      });
      // mousedown, so the pick happens before the input loses focus.
      option.addEventListener('mousedown', function (event) {
        event.preventDefault();
        pick(item);
      });
      list.appendChild(option);
    });
    list.hidden = items.length === 0;
    input.setAttribute('aria-expanded', items.length ? 'true' : 'false');
    setActive(items.length ? 0 : -1);
  };

  const search = function () {
    const found = mention();
    if (!found || !found.query) return close();

    const id = ++latest;
    fetch(form.dataset.suggestionsUrl + '?q=' + encodeURIComponent(found.query), {
      headers: { 'X-Requested-With': 'XMLHttpRequest', Accept: 'application/json' },
      credentials: 'same-origin',
    })
      .then(function (response) { return response.ok ? response.json() : []; })
      .then(function (results) {
        if (id !== latest) return;
        items = results;
        render();
      })
      .catch(close);
  };

  input.addEventListener('input', function () {
    clearTimeout(timer);
    timer = setTimeout(search, 150);
  });

  // Capturing, so Enter picks a suggestion instead of submitting the form.
  input.addEventListener('keydown', function (event) {
    if (list.hidden) return;
    if (event.key === 'ArrowDown') {
      event.preventDefault();
      setActive((active + 1) % items.length);
    } else if (event.key === 'ArrowUp') {
      event.preventDefault();
      setActive((active - 1 + items.length) % items.length);
    } else if (event.key === 'Enter' || event.key === 'Tab') {
      event.preventDefault();
      event.stopPropagation();
      if (items[active]) pick(items[active]);
    } else if (event.key === 'Escape') {
      event.preventDefault();
      close();
    }
  }, true);

  input.addEventListener('blur', close);
  link.querySelector('button').addEventListener('click', function () {
    clearLink();
    input.focus();
  });
});
