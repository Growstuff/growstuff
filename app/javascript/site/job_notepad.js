// The jobs notepad: adding a job, moving it between days, and linking it to a
// crop, planting or seeds, all without reloading the page. The server sends back
// the notepad's groups after each change. If adding a job goes wrong, the job
// stays in the box and a message says so: it is not sent again, since the first
// may have worked and a second would add the job twice. A move or a tick that
// goes wrong reloads the page, which shows how things stand. Choosing Edit in a
// job's menu turns its name into a box to type in; Enter saves, Esc cancels.

import {celebrate, doneText, hide} from './job_celebration';
import {nextStreak, undoStreak} from './job_streak';

document.addEventListener('DOMContentLoaded', function () {
  const form = document.querySelector('.notepad-add');
  const groups = document.getElementById('notepad-groups');
  if (!form || !groups) return;

  const input = form.querySelector('input[type="text"]');
  const failure = document.getElementById('notepad-add-failed');
  const saving = document.getElementById('notepad-add-saving');
  const addButton = form.querySelector('input[type="submit"]');
  const addLabel = addButton.value;
  const token = document.querySelector('meta[name="csrf-token"]');
  const kinds = JSON.parse(form.dataset.kinds);
  // A suggestion's kind (planting, seed or crop) is its type, lower case.
  const kindOf = function (item) { return item.jobbable_type.toLowerCase(); };
  const words = JSON.parse(groups.dataset.celebrations);
  const reload = function () { window.location.reload(); };

  // The line beside the snail says how many jobs are done this week.
  const caption = document.getElementById('notepad-snail-caption');
  const showDone = function (done) {
    if (caption) caption.textContent = done > 0 ? words.slow + ' ' + doneText(words, done) : words.slow;
  };

  // The jobs crossed off since the page loaded. Each request says so, so the
  // server leaves them where they are and a tick never makes a row jump. They
  // move to Done when the page is loaded again.
  const kept = new Set();

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
    kept.forEach(function (id) { body.append('keep[]', id); });
    if (groups.dataset.gardenId) body.append('garden_id', groups.dataset.gardenId);
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

  // Changes one or more of a job's settings, such as {finished: '1'}.
  const patchJob = function (url, attributes) {
    const body = new FormData();
    body.append('_method', 'patch');
    Object.keys(attributes).forEach(function (key) { body.append('job[' + key + ']', attributes[key]); });
    return send(url, body);
  };

  // ---- Crossing a job off, or putting it back

  let streak = 0;
  let lastAt = null;

  groups.addEventListener('submit', function (event) {
    const tick = event.target.closest('.notepad-tick');
    if (!tick) return;
    event.preventDefault();

    const finishing = tick.querySelector('input[name="job[finished]"]').value === '1';
    const row = tick.closest('.notepad-job');
    const name = row.querySelector('.notepad-name').textContent;
    const id = row.dataset.id;
    if (finishing) kept.add(id); else kept.delete(id);
    markSaving(row);
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
            kept.delete(id);
            patchJob(url, {finished: '0'}).catch(reload);
          },
        });
      })
      .catch(function () {
        tick.submit();
      });
  });

  // A row waiting for the server: dimmed, with a spinner, and not to be touched.
  const markSaving = function (row) {
    row.classList.add('saving');
    row.setAttribute('aria-busy', 'true');
    row.draggable = false;
  };

  // ---- Editing a job's name in place

  // The row can't be dragged while it is being edited, or the text couldn't be
  // selected. If saving fails the box stays, so what was typed is not lost.
  const startEditing = function (row) {
    if (row.classList.contains('editing')) return;

    const name = row.querySelector('.notepad-name');
    const original = name.textContent;
    const box = document.createElement('input');
    box.type = 'text';
    box.className = 'notepad-name-input';
    box.value = original;
    box.setAttribute('aria-label', name.dataset.editLabel);
    let finished = false;
    let chosen = null;

    // Typing @ and a crop name here offers links too. The list drops down under
    // the row, and the link picked is shown beside the box until it is saved.
    const options = document.createElement('ul');
    options.id = 'notepad-edit-suggestions';
    options.className = 'notepad-suggestions';
    options.setAttribute('role', 'listbox');
    options.hidden = true;
    const chip = document.createElement('span');
    chip.className = 'notepad-edit-link';
    chip.hidden = true;

    const stop = function () {
      finished = true;
      box.remove();
      options.remove();
      chip.remove();
      name.hidden = false;
      row.classList.remove('editing', 'error');
      row.querySelector('.notepad-edit-hint').hidden = true;
      row.draggable = true;
    };

    const save = function () {
      const typed = box.value.trim();
      if (typed === '' || (typed === original && !chosen)) return stop();

      const changes = {name: typed};
      if (chosen) Object.assign(changes, {jobbable_type: chosen.jobbable_type, jobbable_id: chosen.jobbable_id});

      row.classList.add('saving');
      box.readOnly = true;
      patchJob(row.dataset.url, changes).catch(function () {
        finished = false;
        box.readOnly = false;
        row.classList.remove('saving');
        row.classList.add('error');
        box.focus();
      });
    };

    suggestions(box, options, function (item) {
      chosen = item;
      chip.textContent = kinds[kindOf(item)] + ': ' + item.label;
      chip.hidden = false;
    });

    box.addEventListener('keydown', function (event) {
      if (event.key === 'Enter') {
        event.preventDefault();
        box.blur();
      } else if (event.key === 'Escape') {
        event.preventDefault();
        stop();
      }
    });
    box.addEventListener('blur', function () {
      if (!finished) save();
    });

    row.classList.add('editing');
    row.draggable = false;
    row.querySelector('.notepad-edit-hint').hidden = false;
    name.hidden = true;
    name.after(box);
    box.after(chip);
    row.appendChild(options);
    box.focus();
    box.select();
  };

  groups.addEventListener('click', function (event) {
    const edit = event.target.closest('[data-notepad-edit]');
    if (!edit) return;
    event.preventDefault();
    startEditing(edit.closest('.notepad-job'));
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

  // While a job is on its way, the form says so, so Enter isn't pressed again. The
  // box stays open to type the next job in, but it can't be sent until this is.
  const showSaving = function (name) {
    form.classList.add('saving');
    form.setAttribute('aria-busy', 'true');
    addButton.disabled = true;
    addButton.value = addButton.dataset.savingLabel;
    saving.querySelector('.notepad-add-saving-text').textContent = saving.dataset.template.replace('%{name}', name);
    saving.hidden = false;
  };

  const hideSaving = function () {
    form.classList.remove('saving');
    form.removeAttribute('aria-busy');
    addButton.disabled = false;
    addButton.value = addLabel;
    saving.hidden = true;
  };

  form.addEventListener('submit', function (event) {
    event.preventDefault();
    if (adding || !input.value.trim()) return;
    adding = true;
    failure.hidden = true;
    const submitted = input.value;
    showSaving(submitted);

    send(form.action, new FormData(form))
      .then(function () {
        // Typing the next job while this one was sent is not to be lost.
        if (input.value === submitted) {
          input.value = '';
          clearLink();
        }
        input.focus();
        adding = false;
        hideSaving();
      })
      .catch(function () {
        failure.hidden = false;
        adding = false;
        hideSaving();
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

    // Show the job in its new place at once, marked as saving, so the drop is seen
    // to have worked while the server catches up. The list then replaces it.
    const row = dragged;
    const hint = group.querySelector('.notepad-drop-hint');
    if (hint) hint.remove();
    group.appendChild(row);
    markSaving(row);

    patchJob(row.dataset.url, {due_date: group.dataset.drop === 'none' ? '' : group.dataset.drop}).catch(reload);
  });

  // ---- Linking a job: typing @ and a crop name offers your plantings and seeds
  // of it, then the crop. Picking one swaps the @ text for the crop's name. This
  // works in the add box and in the box a job's name is edited in.

  // Offers suggestions under a text box, listed in the given element. What to do
  // with the one picked is up to onPick.
  const suggestions = function (box, list, onPick) {
    let items = [];
    let active = -1;
    let timer = null;
    let latest = 0;

    box.setAttribute('role', 'combobox');
    box.setAttribute('aria-autocomplete', 'list');
    box.setAttribute('aria-controls', list.id);
    box.setAttribute('aria-expanded', 'false');

    const close = function () {
      items = [];
      active = -1;
      list.hidden = true;
      list.innerHTML = '';
      box.setAttribute('aria-expanded', 'false');
      box.removeAttribute('aria-activedescendant');
    };

    const setActive = function (index) {
      active = index;
      Array.prototype.forEach.call(list.children, function (option, i) {
        option.setAttribute('aria-selected', i === index ? 'true' : 'false');
        option.classList.toggle('active', i === index);
      });
      if (index >= 0) box.setAttribute('aria-activedescendant', list.children[index].id);
    };

    // The @ and the letters after it, up to the cursor.
    const mention = function () {
      const before = box.value.slice(0, box.selectionStart);
      const match = /(^|\s)@([^@]*)$/.exec(before);
      if (!match) return null;
      return {start: match.index + match[1].length, query: match[2].trim()};
    };

    const pick = function (item) {
      const found = mention();
      if (found) {
        const rest = box.value.slice(box.selectionStart).replace(/^\s+/, '');
        const text = box.value.slice(0, found.start) + item.crop_name + ' ';
        box.value = text + rest;
        box.setSelectionRange(text.length, text.length);
      }
      close();
      onPick(item);
      box.focus();
    };

    const render = function () {
      list.innerHTML = '';
      items.forEach(function (item, i) {
        const option = document.createElement('li');
        option.id = list.id + '-' + i;
        option.setAttribute('role', 'option');
        option.className = 'notepad-suggestion';
        const icon = document.createElement('img');
        icon.className = 'notepad-suggestion-icon';
        icon.src = item.icon_url;
        icon.alt = '';
        option.appendChild(icon);
        [['kind', 'span', kinds[kindOf(item)]], ['', 'span', item.label], ['', 'small', item.detail]].forEach(function (part) {
          if (!part[2]) return;
          const el = document.createElement(part[1]);
          el.className = part[0];
          el.textContent = part[2];
          option.appendChild(el);
        });
        // mousedown, so the pick happens before the box loses focus.
        option.addEventListener('mousedown', function (event) {
          event.preventDefault();
          pick(item);
        });
        list.appendChild(option);
      });
      list.hidden = items.length === 0;
      box.setAttribute('aria-expanded', items.length ? 'true' : 'false');
      setActive(items.length ? 0 : -1);
    };

    const search = function () {
      const found = mention();
      if (!found || !found.query) return close();

      const id = ++latest;
      const garden = groups.dataset.gardenId ? '&garden_id=' + encodeURIComponent(groups.dataset.gardenId) : '';
      fetch(form.dataset.suggestionsUrl + '?q=' + encodeURIComponent(found.query) + garden, {
        headers: {'X-Requested-With': 'XMLHttpRequest', Accept: 'application/json'},
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

    box.addEventListener('input', function () {
      clearTimeout(timer);
      timer = setTimeout(search, 150);
    });

    // Capturing, and before the box's own keys, so Enter picks a suggestion
    // instead of submitting or saving, and Escape closes the list first.
    box.addEventListener('keydown', function (event) {
      if (list.hidden) return;
      if (event.key === 'ArrowDown') {
        event.preventDefault();
        setActive((active + 1) % items.length);
      } else if (event.key === 'ArrowUp') {
        event.preventDefault();
        setActive((active - 1 + items.length) % items.length);
      } else if (event.key === 'Enter' || event.key === 'Tab') {
        event.preventDefault();
        event.stopImmediatePropagation();
        if (items[active]) pick(items[active]);
      } else if (event.key === 'Escape') {
        event.preventDefault();
        event.stopImmediatePropagation();
        close();
      }
    }, true);

    box.addEventListener('blur', close);
  };

  // Linking a job being added: the link is shown in a chip, until it is added.
  suggestions(input, document.getElementById('notepad-suggestions'), function (item) {
    typeField.value = item.jobbable_type;
    idField.value = item.jobbable_id;
    link.querySelector('.notepad-link-text').textContent = kinds[kindOf(item)] + ': ' + item.label;
    link.hidden = false;
  });

  link.querySelector('button').addEventListener('click', function () {
    clearLink();
    input.focus();
  });
});
