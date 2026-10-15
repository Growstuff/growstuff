// The full screen search a phone gets from the magnifier in the top bar: put
// the cursor in the field when it opens, and list the crops that match as the
// member types.
document.addEventListener('DOMContentLoaded', function() {
  var panel = document.getElementById('phoneSearch');
  if (!panel) return;

  var field = document.getElementById('phone-term');
  var results = panel.querySelector('.phone-search-results');
  var list = results.querySelector('.phone-search-list');
  var all = results.querySelector('.phone-search-all');
  var template = document.getElementById('phone-search-row');
  var searchUrl = results.getAttribute('data-url');
  var allLabel = results.getAttribute('data-all-label');
  var allUrl = panel.querySelector('form').getAttribute('action');
  var timer;
  var latest = 0;

  function show(term, crops) {
    list.replaceChildren();
    crops.slice(0, 8).forEach(function(crop) {
      var row = template.content.firstElementChild.cloneNode(true);
      row.href = '/crops/' + encodeURIComponent(crop.slug);
      row.querySelector('span').textContent = crop.name;
      list.appendChild(row);
    });
    all.href = allUrl + '?term=' + encodeURIComponent(term);
    all.querySelector('span').textContent = allLabel.replace('__term__', term);
    results.hidden = false;
  }

  function search(term) {
    var request = ++latest;
    if (!term) {
      results.hidden = true;
      return;
    }
    fetch(searchUrl + '?term=' + encodeURIComponent(term), {headers: {Accept: 'application/json'}})
        .then(function(response) { return response.json(); })
        .then(function(crops) {
          if (request === latest) show(term, crops);
        })
        .catch(function() {});
  }

  field.addEventListener('input', function() {
    clearTimeout(timer);
    var term = field.value.trim();
    timer = setTimeout(function() { search(term); }, 200);
  });

  panel.addEventListener('shown.bs.offcanvas', function() { field.focus(); });
  panel.addEventListener('hidden.bs.offcanvas', function() {
    field.value = '';
    search('');
  });
});
