// On a phone the magnifier in the top bar opens the menu, where the search
// field is; put the cursor in the field once the menu has opened.
document.addEventListener('DOMContentLoaded', function() {
  var wantsSearch = false;

  document.addEventListener('click', function(event) {
    wantsSearch = !!event.target.closest('.navbar-search-toggle');
  });

  document.addEventListener('shown.bs.collapse', function(event) {
    if (event.target.id !== 'navbarSupportedContent' || !wantsSearch) return;

    var field = document.getElementById('term');
    if (field) field.focus();
    wantsSearch = false;
  });
});
