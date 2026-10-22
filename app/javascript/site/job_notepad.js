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
