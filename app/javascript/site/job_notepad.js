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
