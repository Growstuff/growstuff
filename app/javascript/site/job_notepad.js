// Adds a job to the notepad without reloading the page: the server sends back
// the notepad's groups with the new job in them. If anything goes wrong the form
// is submitted the ordinary way, so nothing is lost.

document.addEventListener('DOMContentLoaded', function () {
  const form = document.querySelector('.notepad-add');
  const groups = document.getElementById('notepad-groups');
  if (!form || !groups) return;

  const input = form.querySelector('input[type="text"]');
  const token = document.querySelector('meta[name="csrf-token"]');
  let adding = false;

  form.addEventListener('submit', function (event) {
    event.preventDefault();
    if (adding || !input.value.trim()) return;
    adding = true;

    fetch(form.action, {
      method: 'POST',
      body: new FormData(form),
      headers: {
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': token ? token.content : '',
      },
      credentials: 'same-origin',
    })
      .then(function (response) {
        if (!response.ok) throw new Error(response.status);
        return response.text();
      })
      .then(function (html) {
        groups.innerHTML = html;
        input.value = '';
        if (window.jobNotepadClearLink) window.jobNotepadClearLink();
        input.focus();
        adding = false;
      })
      .catch(function () {
        form.submit();
      });
  });
});

// Dragging a job into Today, This week or Some day gives it that day. Each group
// says which day in data-drop ("none" for no day). The row menu does the same
// for keyboard and touch.
document.addEventListener('DOMContentLoaded', function () {
  const groups = document.getElementById('notepad-groups');
  if (!groups) return;

  const token = document.querySelector('meta[name="csrf-token"]');
  let dragged = null;

  const dropTarget = function (event) {
    const group = event.target.closest('.notepad-group');
    return group && group.dataset.drop ? group : null;
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
    groups.querySelectorAll('.drop-over').forEach(function (el) { el.classList.remove('drop-over'); });
  });

  groups.addEventListener('dragover', function (event) {
    const group = dropTarget(event);
    if (!dragged || !group) return;
    event.preventDefault();
    groups.querySelectorAll('.drop-over').forEach(function (el) { el.classList.remove('drop-over'); });
    group.classList.add('drop-over');
  });

  groups.addEventListener('drop', function (event) {
    const group = dropTarget(event);
    if (!dragged || !group) return;
    event.preventDefault();

    const body = new FormData();
    body.append('_method', 'patch');
    body.append('job[due_date]', group.dataset.drop === 'none' ? '' : group.dataset.drop);

    fetch(dragged.dataset.url, {
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
        return response.text();
      })
      .then(function (html) {
        groups.innerHTML = html;
      })
      .catch(function () {
        window.location.reload();
      });
  });
});

// Typing @ and a crop name offers your plantings and seeds of it, then the crop.
// Picking one swaps the @ text for the crop's name and links the job to it.
document.addEventListener('DOMContentLoaded', function () {
  const form = document.querySelector('.notepad-add');
  if (!form || !form.dataset.suggestionsUrl) return;

  const input = form.querySelector('input[type="text"]');
  const list = document.getElementById('notepad-suggestions');
  const link = document.getElementById('notepad-link');
  const typeField = document.getElementById('notepad-jobbable-type');
  const idField = document.getElementById('notepad-jobbable-id');
  let items = [];
  let active = -1;
  let timer = null;
  let request = 0;

  const kindNames = { planting: 'Planting', seed: 'Seeds', crop: 'Crop' };

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
  const token = function () {
    const before = input.value.slice(0, input.selectionStart);
    const match = /(^|\s)@([^@]*)$/.exec(before);
    if (!match) return null;
    return { start: match.index + match[1].length, query: match[2].trim() };
  };

  const render = function () {
    list.innerHTML = '';
    items.forEach(function (item, i) {
      const option = document.createElement('li');
      option.id = 'notepad-suggestion-' + i;
      option.setAttribute('role', 'option');
      option.className = 'notepad-suggestion';
      const kind = document.createElement('span');
      kind.className = 'kind';
      kind.textContent = kindNames[item.kind];
      const label = document.createElement('span');
      label.textContent = item.label;
      option.appendChild(kind);
      option.appendChild(label);
      if (item.detail) {
        const detail = document.createElement('small');
        detail.textContent = item.detail;
        option.appendChild(detail);
      }
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

  const clearLink = function () {
    typeField.value = '';
    idField.value = '';
    link.hidden = true;
  };
  window.jobNotepadClearLink = clearLink;

  const showLink = function (item) {
    clearLink();
    typeField.value = item.jobbable_type;
    idField.value = item.jobbable_id;
    link.querySelector('.notepad-link-text').textContent = kindNames[item.kind] + ': ' + item.label;
    link.querySelector('button').setAttribute('aria-label', 'Remove link to ' + item.label);
    link.hidden = false;
  };

  const pick = function (item) {
    const found = token();
    if (found) {
      const rest = input.value.slice(input.selectionStart);
      const text = input.value.slice(0, found.start) + item.crop_name + ' ';
      input.value = text + rest.replace(/^\s+/, '');
      input.setSelectionRange(text.length, text.length);
    }
    showLink(item);
    close();
    input.focus();
  };

  const search = function () {
    const found = token();
    if (!found || !found.query) return close();

    const id = ++request;
    fetch(form.dataset.suggestionsUrl + '?q=' + encodeURIComponent(found.query), {
      headers: { 'X-Requested-With': 'XMLHttpRequest', Accept: 'application/json' },
      credentials: 'same-origin',
    })
      .then(function (response) { return response.ok ? response.json() : []; })
      .then(function (results) {
        if (id !== request) return;
        items = results;
        render();
      })
      .catch(close);
  };

  input.addEventListener('input', function () {
    clearTimeout(timer);
    timer = setTimeout(search, 150);
  });

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
