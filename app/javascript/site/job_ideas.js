// The ideas as an overlay over the jobs. The links to the ideas open it, and
// choosing an idea sends it without leaving the page. An idea that was added shows
// the jobs it made, one after another, and the same jobs slide into the notepad
// behind. Then the idea makes way and the next takes its place. If anything goes
// wrong the choice is sent the ordinary way, which shows the ideas on their page.

const reduced = function () {
  return !!(window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches);
};

// Waits for an animation to be seen; not at all for those who ask for less motion.
const wait = function (ms) {
  return new Promise(function (resolve) { setTimeout(resolve, reduced() ? 0 : ms); });
};

// The jobs an idea made, as a line to take the idea's place: each job appears a
// moment after the one before.
export const addedBlock = function (data) {
  const block = document.createElement('div');
  block.className = 'idea-added';
  const label = document.createElement('p');
  label.className = 'idea-added-label';
  label.textContent = '✓ ' + data.added_label;
  block.appendChild(label);
  const list = document.createElement('ul');
  data.added.forEach(function (job, index) {
    const item = document.createElement('li');
    item.style.animationDelay = (index * 90) + 'ms';
    item.textContent = job.due ? job.due + ' ' + job.name : job.name;
    list.appendChild(item);
  });
  block.appendChild(list);
  return block;
};

document.addEventListener('DOMContentLoaded', function () {
  const modal = document.getElementById('job-ideas-modal');
  const body = document.getElementById('job-ideas-body');
  if (!modal || !body) return;

  const token = document.querySelector('meta[name="csrf-token"]');
  const request = function (url, options) {
    const settings = options || {};
    return fetch(url, Object.assign({credentials: 'same-origin'}, settings, {
      headers: Object.assign({'X-Requested-With': 'XMLHttpRequest', 'X-CSRF-Token': token ? token.content : ''}, settings.headers),
    }));
  };
  const ok = function (response) {
    if (!response.ok) throw new Error(response.status);
    return response;
  };

  const keys = function () {
    return Array.from(body.querySelectorAll('.idea')).map(function (idea) { return idea.dataset.key; });
  };

  // Shows the ideas, those that were not there before sliding in.
  const showList = function (html) {
    const before = new Set(keys());
    body.innerHTML = html;
    body.querySelectorAll('.idea').forEach(function (idea) {
      if (!before.has(idea.dataset.key) && before.size) idea.classList.add('idea-entering');
    });
  };

  const load = function (url) {
    return request(url, {headers: {Accept: 'text/html'}}).then(ok).then(function (response) { return response.text(); }).then(showList);
  };

  const open = function () {
    window.bootstrap.Modal.getOrCreateInstance(modal).show();
  };

  // How many ideas there are, in the box over the jobs.
  const showCount = function (data) {
    document.querySelectorAll('.notepad-ideas').forEach(function (box) {
      const text = box.querySelector('.notepad-ideas-text');
      if (text) text.textContent = data.banner;
      box.hidden = data.count === 0;
    });
  };

  // The jobs, as they now are, with the new ones marked so they can be seen to
  // arrive.
  const showJobs = function (data) {
    const groups = document.getElementById('notepad-groups');
    if (!groups || !data.groups) return;
    const added = new Set(data.added.map(function (job) { return String(job.id); }));
    groups.innerHTML = data.groups;
    groups.querySelectorAll('.notepad-job').forEach(function (row) {
      if (added.has(row.dataset.id)) row.classList.add('just-added');
    });
  };

  // Sends the choice. Rejects only if it could not be sent, or the answer was no
  // good: then it is safe to send it again the ordinary way.
  const send = function (form) {
    return request(form.action, {method: 'POST', body: new FormData(form), headers: {Accept: 'application/json'}})
      .then(ok)
      .then(function (response) { return response.json(); });
  };

  // Shows what the server did. If that goes wrong the choice was made all the
  // same, so the page is loaded again to show how things stand.
  const show = function (form, data) {
    const row = form.closest('.idea');
    return Promise.resolve()
      .then(function () {
        showCount(data);
        showJobs(data);
        if (data.added.length && row) {
          row.replaceChildren(addedBlock(data));
          row.classList.remove('idea-working');
          row.classList.add('idea-confirmed');
          return wait(Math.min(2600, 1100 + data.added.length * 140));
        }
        if (row) row.classList.add('idea-leaving');
        return wait(350);
      })
      .then(function () { showList(data.list); })
      .catch(function () { window.location.reload(); });
  };

  const choose = function (form) {
    const row = form.closest('.idea');
    if (row) row.classList.add('idea-working');
    return send(form).then(function (data) { return show(form, data); }, function () { form.submit(); });
  };

  // Sent here from the front page, with the ideas to show.
  const url = new URL(window.location.href);
  if (url.searchParams.has('ideas')) {
    url.searchParams.delete('ideas');
    window.history.replaceState(null, '', url.pathname + url.search + url.hash);
    load(modal.dataset.url).then(open).catch(function () {});
  }

  document.querySelectorAll('[data-job-ideas-open]').forEach(function (link) {
    link.addEventListener('click', function (event) {
      if (event.metaKey || event.ctrlKey || event.shiftKey) return;
      event.preventDefault();
      load(modal.dataset.url).then(open).catch(function () { window.location.href = link.href; });
    });
  });

  body.addEventListener('click', function (event) {
    const filter = event.target.closest('.idea-filter');
    if (!filter) return;
    event.preventDefault();
    load(filter.href).catch(function () { window.location.href = filter.href; });
  });

  body.addEventListener('submit', function (event) {
    const form = event.target.closest('.idea-form');
    if (!form) return;
    event.preventDefault();
    choose(form);
  });
});
