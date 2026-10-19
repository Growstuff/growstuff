// TODO: This assumes one autocomplete per page.
// Needs to be a function so that when we append one of these, it gets uniquely associated with the hidden controls.
jQuery(function () {
  const el = $('.scientific-name-auto-suggest');
  if (!el.length) return;

  const id = $('.scientific-name-auto-suggest-id');

  el.autocomplete({
    minLength: 3,
    source: el.attr('data-source-url'),
    focus: function (event, ui) {
      el.val(ui.item.canonicalName);
      id.val(ui.item.nameKey);
      return false;
    },
    select: function (event, ui) {
      el.val(ui.item.canonicalName);
      id.val(ui.item.nameKey);
      return false;
    },
    response: function (event, ui) {
      id.val('');
      ui.content.forEach(function (item) {
        if (item.name === el.val()) id.val(item.nameKey);
      });
    }
  });

  const autocomplete = el.data('uiAutocomplete');
  if (autocomplete) {
    autocomplete._renderItem = function (ul, item) {
      return $('<li class="list-group-item"></li>')
        .data('item.autocomplete', item)
        .append(`<a>${item.canonicalName} (${item.scientificName}) - ${item.rank}</a>`)
        .appendTo(ul);
    };
  }
});
